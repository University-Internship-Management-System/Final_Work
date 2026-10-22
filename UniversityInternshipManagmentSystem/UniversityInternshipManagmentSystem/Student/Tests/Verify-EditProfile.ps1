$ErrorActionPreference = 'Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$assembly=Join-Path $root 'bin/UniversityInternshipManagmentSystem.dll'
$json=Join-Path $root 'bin/Newtonsoft.Json.dll'
[void][Reflection.Assembly]::LoadFrom($json)
[void][Reflection.Assembly]::LoadFrom($assembly)
[xml]$teamConfig = Get-Content (Join-Path $root 'Web.config')
[UniversityInternshipManagmentSystem.Config.AppConfig]::DbUrl = ($teamConfig.configuration.appSettings.add | Where-Object { $_.key -eq 'DbUrl' }).value
Add-Type -ReferencedAssemblies @($assembly,$json,'System.Core','System.Web','System.Net.Http') -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Student.Data;

public static class EditProfileChecks
{
    private static int checks;
    private static void Check(bool condition, string description) { if (!condition) throw new Exception(description); checks++; }
    private static void Reject(Action action, string description)
    {
        try { action(); }
        catch (ArgumentException) { checks++; return; }
        catch (UnauthorizedAccessException) { checks++; return; }
        catch (StudentDataException) { checks++; return; }
        throw new Exception(description);
    }
    private static StudentAccess Access()
    {
        return new StudentAccess { StudentId="student_001", FirebaseUid="offline-uid", FirebaseIdToken="offline-token",
            ExpiresUtc=DateTimeOffset.UtcNow.AddMinutes(5), EditableFields=ProfileValidation.EditableFields };
    }
    private static FirebaseStudentRepository Repository(StudentAccess access, FakeFirebase transport)
    {
        var constructor=typeof(FirebaseStudentRepository).GetConstructor(BindingFlags.NonPublic | BindingFlags.Instance, null,
            new[] { typeof(StudentAccess), typeof(HttpClient) }, null);
        try { return (FirebaseStudentRepository)constructor.Invoke(new object[] { access, new HttpClient(transport) }); }
        catch (TargetInvocationException error) { throw error.InnerException; }
    }
    public static string Run()
    {
        var previous=Environment.GetEnvironmentVariable("UIMS_STUDENT_PROFILE_WRITES_APPROVED");
        try
        {
            Environment.SetEnvironmentVariable("UIMS_STUDENT_PROFILE_WRITES_APPROVED", null);
            var all=ProfileValidation.EditableFields;
            var patch=ProfileValidation.CreatePatch(" +962 700000101 ", " C#\r\nSQL\nc#\n ", " https://example.com/cv ", "", all);
            Check((string)patch["PhoneNumber"]=="+962 700000101" && ((IList<string>)patch["SkillsList"]).SequenceEqual(new[] {"C#","SQL"}), "Fields trim and skills deduplicate");
            Check(patch.Keys.OrderBy(x=>x).SequenceEqual(all.OrderBy(x=>x)), "Only four permitted fields are constructed");
            var subset=ProfileValidation.CreatePatch("1234567", "bad ignored", "bad ignored", "bad ignored", new HashSet<string> { "PhoneNumber" });
            Check(subset.Count==1 && subset.ContainsKey("PhoneNumber"), "Session subset is respected");
            foreach (var field in new[] {"Name","Email","UniEmail","Major","GPA","Role","AuthUid","CompanyId","AcademicSupervisorId","PhoneNumber/Name","../Name"})
                Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object> { {field,"forged"} }, new HashSet<string> {field}), "Protected or path field allowed");
            foreach (var phone in new[] {"-------", "123456", "+1234567\n", "1234567<script>", new string('1',31)})
                Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object> { {"PhoneNumber",phone} },all), "Invalid phone allowed");
            foreach (var link in new[] {"http://example.com", "javascript:alert(1)", "//example.com", "https://user:secret@example.com", "https://example.com/\n", new string('x',2049)})
                Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object> { {"CvUrl",link} },all), "Invalid URL allowed");
            Reject(()=>ProfileValidation.CreatePatch("",string.Join("\n",Enumerable.Range(1,21).Select(x=>"skill"+x)),"","",all),"Too many skills allowed");
            Reject(()=>ProfileValidation.CreatePatch("",new string('x',61),"","",all),"Oversized skill allowed");
            Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object> { {"SkillsList",new List<string>{"a\tb"}} },all),"Control character in skill allowed");
            Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object> { {"SkillsList","not a list"} },all),"Wrong skills type allowed");
            var fake=new FakeFirebase(); var repo=Repository(Access(),fake);
            Reject(()=>repo.UpdateProfileAsync(patch).GetAwaiter().GetResult(),"Default gate allowed writes");
            Check(fake.Calls==0,"Disabled writes send no request");

            // Opt-in is confined to this separate test process; ALL requests use FakeFirebase.
            Environment.SetEnvironmentVariable("UIMS_STUDENT_PROFILE_WRITES_APPROVED","true");
            repo.UpdateProfileAsync(patch).GetAwaiter().GetResult();
            Check(fake.Methods.SequenceEqual(new[]{"GET","PATCH","GET"}),"Ownership read, field PATCH, persistence read-back");
            Check(fake.LastPatch.Properties().Select(x=>x.Name).OrderBy(x=>x).SequenceEqual(all.OrderBy(x=>x)),"PATCH body contains only approved fields");
            Check((string)fake.Record["Name"]=="Offline repository fixture" && (string)fake.Record["AuthUid"]=="offline-uid","Academic/identity fields preserved");
            var cleared=ProfileValidation.CreatePatch("","","","",all);
            repo.UpdateProfileAsync(cleared).GetAwaiter().GetResult();
            Check(fake.LastPatch["SkillsList"].Type==JTokenType.Array && fake.LastPatch["SkillsList"].Count()==0,"Clearing skills uses empty list, not arbitrary deletion");

            fake=new FakeFirebase(); fake.Record["AuthUid"]="another-user"; repo=Repository(Access(),fake);
            Reject(()=>repo.UpdateProfileAsync(patch).GetAwaiter().GetResult(),"Foreign record write allowed");
            Check(!fake.Methods.Contains("PATCH"),"AuthUid mismatch blocks PATCH");
            fake=new FakeFirebase(); var access=Access(); access.FirebaseUid=null;
            Reject(()=>Repository(access,fake),"Missing verified UID allowed at construction");
            Check(fake.Calls==0,"Missing UID fails before network");
            fake=new FakeFirebase(); access=Access(); access.EditableFields=new HashSet<string>(); repo=Repository(access,fake);
            access.EditableFields.Add("PhoneNumber");
            Reject(()=>repo.UpdateProfileAsync(new Dictionary<string,object>{{"PhoneNumber","1234567"}}).GetAwaiter().GetResult(),"Permission snapshot expanded");
            Check(fake.Calls==0,"Unapproved fields fail before network");
            fake=new FakeFirebase { DenyPatch=true }; repo=Repository(Access(),fake);
            Reject(()=>repo.UpdateProfileAsync(patch).GetAwaiter().GetResult(),"Firebase permission denial treated as success");
            Check(fake.Methods.SequenceEqual(new[]{"GET","PATCH"}),"Rules denial is not retried or bypassed");
            fake=new FakeFirebase { IgnorePatch=true }; repo=Repository(Access(),fake);
            Reject(()=>repo.UpdateProfileAsync(patch).GetAwaiter().GetResult(),"Unconfirmed persistence treated as success");
            Check(fake.Methods.SequenceEqual(new[]{"GET","PATCH","GET"}),"Read-back mismatch detected");
            fake=new FakeFirebase(); repo=Repository(Access(),fake);
            Reject(()=>repo.UpdateProfileAsync(new Dictionary<string,object>{{"Role","Admin"}}).GetAwaiter().GetResult(),"Overposting accepted");
            Check(fake.Calls==0,"Overposting sends no request");
            return "PASS: "+checks+" Edit Profile validation/authorization/PATCH/read-back checks; fake transport only, no live Firebase writes.";
        }
        finally { Environment.SetEnvironmentVariable("UIMS_STUDENT_PROFILE_WRITES_APPROVED",previous); }
    }
    private sealed class FakeFirebase : HttpMessageHandler
    {
        public int Calls;
        public bool DenyPatch,IgnorePatch;
        public List<string> Methods=new List<string>();
        public JObject LastPatch;
        public JObject Record=JObject.Parse("{\"Name\":\"Offline repository fixture\",\"Role\":\"Student\",\"AuthUid\":\"offline-uid\",\"PhoneNumber\":\"1234567\",\"SkillsList\":[\"old\"],\"CvUrl\":\"\",\"PortfolioUrl\":\"\"}");
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,CancellationToken cancellation)
        {
            Calls++; Methods.Add(request.Method.Method);
            if(request.RequestUri.Scheme!="https" || request.RequestUri.Host!=new Uri(FirebaseStudentRepository.DatabaseUrl).Host
                || request.RequestUri.AbsolutePath!="/Students/student_001.json" || request.RequestUri.Query!="?auth=offline-token")
                throw new Exception("Wrong repository resource or token binding");
            if(request.Method.Method=="PATCH")
            {
                if(DenyPatch) return new HttpResponseMessage(HttpStatusCode.Forbidden);
                LastPatch=JObject.Parse(await request.Content.ReadAsStringAsync());
                if(!IgnorePatch) foreach(var property in LastPatch.Properties()) Record[property.Name]=property.Value.DeepClone();
                return new HttpResponseMessage(HttpStatusCode.OK){Content=new StringContent(LastPatch.ToString(),Encoding.UTF8,"application/json")};
            }
            if(request.Method!=HttpMethod.Get) throw new Exception("Non-PATCH write attempted");
            return new HttpResponseMessage(HttpStatusCode.OK){Content=new StringContent(Record.ToString(),Encoding.UTF8,"application/json")};
        }
    }
}
'@
[EditProfileChecks]::Run()
