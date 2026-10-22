param([string]$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')))
$ErrorActionPreference = 'Stop'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('uims-academic-account-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temporary)
$fixture = @'
using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Academic.SupervisorAccount;

public static class AcademicProfileChecks
{
    private static int checks;
    private static void Check(bool ok, string label) { if (!ok) throw new Exception(label); checks++; }
    private sealed class Session : HttpSessionStateBase {
        private readonly Dictionary<string, object> values = new Dictionary<string, object>();
        public override object this[string name] { get { object v; return values.TryGetValue(name, out v) ? v : null; } set { values[name] = value; } }
    }
    private static string Encode(string value) { return Convert.ToBase64String(Encoding.UTF8.GetBytes(value)).TrimEnd('=').Replace('+','-').Replace('/','_'); }
    // Deliberately unsigned OFFLINE fixture: only the fake HTTP handler accepts it.
    // Production trusts Google's HTTPS token-verification response, never this token generator.
    private static string Token(string project = "offline-academic", long expiry = 0, string subject = "uid-fixture", string algorithm = "RS256") {
        long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var claims = new JObject { {"sub",subject}, {"aud",project}, {"iss","https://securetoken.google.com/"+project},
            {"exp",expiry == 0 ? now+600 : expiry}, {"iat",now-10}, {"auth_time",now-10} };
        return Encode(new JObject { {"alg",algorithm},{"kid","offline"} }.ToString())+"."+Encode(claims.ToString())+".offline";
    }
    private sealed class Transport : HttpMessageHandler {
        internal int Calls;
        internal bool DenyIdentity, Disabled, DenyWrite, DenyPassword, MismatchReauth, MismatchUpdate, IgnoreWrite;
        internal int Writes, PasswordWrites;
        internal JObject LastPatch;
        internal string LocalId = "uid-fixture", ValidSince = "0";
        internal HttpStatusCode ReadStatus = HttpStatusCode.OK;
        internal string Body = "{\"Name\":\"<script>fixture</script>\",\"Email\":\"fixture@example.invalid\",\"Role\":\"AcademicSupervisor\",\"FirstLogin\":false}";
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellation) {
            Calls++;
            if(request.Method == HttpMethod.Post && request.RequestUri.Host == "identitytoolkit.googleapis.com"
                && request.RequestUri.AbsolutePath == "/v1/accounts:lookup") {
                var identity = new JObject { {"users", new JArray(new JObject { {"localId",LocalId}, {"disabled",Disabled}, {"validSince",ValidSince} })} };
                return Task.FromResult(new HttpResponseMessage(DenyIdentity ? HttpStatusCode.BadRequest : HttpStatusCode.OK) { Content = new StringContent(identity.ToString()) });
            }
            if (request.Method.Method == "PATCH") {
                Check(request.RequestUri.AbsolutePath == "/AcademicSupervisors/uid-fixture.json", "Foreign account write");
                Check(HttpUtility.ParseQueryString(request.RequestUri.Query)["auth"] != null, "Write token missing");
                LastPatch=JObject.Parse(request.Content.ReadAsStringAsync().GetAwaiter().GetResult());
                Check(LastPatch.Count==3 && LastPatch["Name"]!=null && LastPatch["PhoneNumber"]!=null && LastPatch["ProfilePicUrl"]!=null,"Overposting sent to Firebase");
                Writes++;
                if(!DenyWrite && !IgnoreWrite) { var record=JObject.Parse(Body); foreach(var field in LastPatch.Properties()) record[field.Name]=field.Value.DeepClone(); Body=record.ToString(); }
                return Task.FromResult(new HttpResponseMessage(DenyWrite?HttpStatusCode.Forbidden:HttpStatusCode.OK){Content=new StringContent(LastPatch.ToString())});
            }
            if (request.Method==HttpMethod.Post && request.RequestUri.AbsolutePath=="/v1/accounts:signInWithPassword") {
                var data=JObject.Parse(request.Content.ReadAsStringAsync().GetAwaiter().GetResult());
                Check((string)data["email"]=="fixture@example.invalid", "Reauthentication email was not server-derived");
                return Task.FromResult(new HttpResponseMessage(DenyPassword?HttpStatusCode.BadRequest:HttpStatusCode.OK){Content=new StringContent(new JObject{{"localId",MismatchReauth?"foreign":"uid-fixture"},{"idToken",Token()}}.ToString())});
            }
            if (request.Method==HttpMethod.Post && request.RequestUri.AbsolutePath=="/v1/accounts:update") {
                PasswordWrites++;
                var data=JObject.Parse(request.Content.ReadAsStringAsync().GetAwaiter().GetResult());
                Check(data.Count==3 && data["password"]!=null && data["idToken"]!=null,"Unexpected auth-update fields");
                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK){Content=new StringContent(new JObject{{"localId",MismatchUpdate?"foreign":"uid-fixture"},{"idToken",Token()}}.ToString())});
            }
            Check(request.Method == HttpMethod.Get, "A database write was attempted");
            Check(request.RequestUri.AbsolutePath == "/AcademicSupervisors/uid-fixture.json", "Unexpected record/table scan");
            Check(request.RequestUri.Host == "offline-academic-default-rtdb.firebaseio.com", "Wrong database");
            Check(HttpUtility.ParseQueryString(request.RequestUri.Query)["auth"] != null, "Missing authenticated token");
            return Task.FromResult(new HttpResponseMessage(ReadStatus) { Content = new StringContent(Body) });
        }
    }
    private static void Reject(AcademicAccountReader reader, HttpSessionStateBase session, int status) {
        try { reader.LoadAsync(session).GetAwaiter().GetResult(); }
        catch(AccountAccessException e) { Check(e.StatusCode == status, "Wrong rejection status: "+e.StatusCode); return; }
        throw new Exception("Unauthorized or failed read accepted");
    }
    private static void BindingChecks() {
        var page = new SupervisorAccount();
        var fields = typeof(SupervisorAccount).GetFields(System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.DeclaredOnly);
        foreach(var field in fields) if(typeof(System.Web.UI.Control).IsAssignableFrom(field.FieldType))
            field.SetValue(page, Activator.CreateInstance(field.FieldType));
        var bind = typeof(SupervisorAccount).GetMethod("BindSupervisorData",System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        // Supply a real HttpContext for Web Forms Server.HtmlEncode, without an authenticated session.
        HttpContext.Current = new HttpContext(new HttpRequest("", "http://localhost/", ""), new HttpResponse(new System.IO.StringWriter()));
        try {
            bind.Invoke(page,new object[] { new JObject { {"Name","<script>alert(1)</script>"}, {"Role","AcademicSupervisor"}, {"ProfilePicUrl","javascript:alert(1)"} } });
            var name=(System.Web.UI.WebControls.Literal)typeof(SupervisorAccount).GetField("litProfileName",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic).GetValue(page);
            Check(name.Text=="&lt;script&gt;alert(1)&lt;/script&gt;", "Actual page binding did not encode output");
            var image=(System.Web.UI.WebControls.Panel)typeof(SupervisorAccount).GetField("pnlImageAvatar",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic).GetValue(page);
            Check(!image.Visible,"Unsafe avatar scheme displayed");
            var email=(System.Web.UI.WebControls.TextBox)typeof(SupervisorAccount).GetField("txtOfficeNumber",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic).GetValue(page);
            Check(email.Text=="Not provided","Page fabricated UniversityEmail");
            bind.Invoke(page,new object[] { new JObject { {"Role","AcademicSupervisor"} } });
            Check(name.Text=="Not provided","Missing name not displayed honestly");
        } finally { HttpContext.Current = null; }
    }
    private static void Refuse(Action action,string label) {
        try {action();} catch(ArgumentException){checks++;return;} catch(AccountAccessException){checks++;return;}
        throw new Exception(label);
    }
    private static void WriteChecks() {
        var t=new Transport(); var reader=new AcademicAccountReader(new HttpClient(t),"https://offline-academic-default-rtdb.firebaseio.com/","offline-client-key");
        var session=new Session();session["userId"]="uid-fixture";session["idToken"]=Token();session["role"]="academic";session["dbTable"]="AcademicSupervisors";session["dbRecordId"]="uid-fixture";
        var patch=AcademicAccountReader.ProfilePatch("Updated fixture","+962 790000000","https://example.invalid/avatar.png");
        Check(patch.Count==3&&patch["Major"]==null&&patch["Email"]==null&&patch["UniversityEmail"]==null,"Editable allowlist expanded");
        foreach(var name in new[]{"",new string('x',101),"<script>","name\n"}) {
            if(name=="name\n") continue; // surrounding whitespace is intentionally trimmed
            Refuse(()=>AcademicAccountReader.ProfilePatch(name,"",""),"Invalid name accepted");
        }
        Refuse(()=>AcademicAccountReader.ProfilePatch("Name","bad phone",""),"Invalid phone accepted");
        foreach(var image in new[]{"http://example.invalid/p","javascript:alert(1)","https://u:p@example.invalid/p",new string('x',2049)})
            Refuse(()=>AcademicAccountReader.ProfilePatch("Name","",image),"Unsafe image accepted");
        SupervisorAccount.RequireCsrf("fixture-csrf","fixture-csrf");
        Refuse(()=>SupervisorAccount.RequireCsrf(null,null),"Empty CSRF accepted");
        Refuse(()=>SupervisorAccount.RequireCsrf("expected","foreign"),"Foreign CSRF accepted");
        var saved=reader.SaveAsync(session,patch).GetAwaiter().GetResult();
        Check(t.Writes==1&&(string)saved["Name"]=="Updated fixture"&&(string)saved["Role"]=="AcademicSupervisor","PATCH/read-back failed or overwrote role");
        var over=(JObject)patch.DeepClone();over["Role"]="Admin";int before=t.Writes;
        Refuse(()=>reader.SaveAsync(session,over).GetAwaiter().GetResult(),"Extra field accepted");Check(t.Writes==before,"Overposting reached Firebase");
        session["dbRecordId"]="foreign";Refuse(()=>reader.SaveAsync(session,patch).GetAwaiter().GetResult(),"Foreign account write accepted");Check(t.Writes==before,"Foreign account reached write");session["dbRecordId"]="uid-fixture";
        t.DenyWrite=true;Refuse(()=>reader.SaveAsync(session,patch).GetAwaiter().GetResult(),"Denied write reported success");t.DenyWrite=false;
        t.IgnoreWrite=true;var different=AcademicAccountReader.ProfilePatch("Different","","");Refuse(()=>reader.SaveAsync(session,different).GetAwaiter().GetResult(),"Unpersisted write reported success");t.IgnoreWrite=false;
        foreach(var values in new[]{new[]{"","newpass","newpass"},new[]{"current","short","short"},new[]{"current","newpass","different"},new[]{"current","current","current"}})
            Refuse(()=>AcademicAccountReader.ValidatePassword(values[0],values[1],values[2]),"Invalid password accepted");
        t.Body="{\"Role\":\"AcademicSupervisor\",\"Email\":\"fixture@example.invalid\"}";
        t.DenyPassword=true;Refuse(()=>reader.ChangePasswordAsync(session,"current","newpass","newpass").GetAwaiter().GetResult(),"Wrong current password accepted");Check(t.PasswordWrites==0,"Wrong password caused update");t.DenyPassword=false;
        t.MismatchReauth=true;Refuse(()=>reader.ChangePasswordAsync(session,"current","newpass","newpass").GetAwaiter().GetResult(),"Foreign reauth accepted");Check(t.PasswordWrites==0,"Foreign reauth caused update");t.MismatchReauth=false;
        reader.ChangePasswordAsync(session,"current","newpass","newpass").GetAwaiter().GetResult();Check(t.PasswordWrites==1&&!string.IsNullOrEmpty(session["idToken"] as string),"Password workflow/token renewal failed");
        t.MismatchUpdate=true;Refuse(()=>reader.ChangePasswordAsync(session,"current","newpass","newpass").GetAwaiter().GetResult(),"Foreign updated identity accepted");Check(session["idToken"]==null,"Unsafe session token retained");
    }
    public static void Run() {
        var transport = new Transport();
        var reader = new AcademicAccountReader(new HttpClient(transport), "https://offline-academic-default-rtdb.firebaseio.com/", "offline-client-key");
        var session = new Session();
        Reject(reader, session, 401);
        Check(transport.Calls == 0, "Anonymous request reached network");
        session["userId"]="uid-fixture"; session["idToken"]=Token(); session["role"]="academic";
        session["dbTable"]="AcademicSupervisors"; session["dbRecordId"]="uid-fixture";
        foreach(var invalid in new Dictionary<string,object> { {"role","coordinator"},{"dbTable","Admins"},{"dbRecordId","email-matched-legacy-key"},{"idToken",""} }) {
            object old = session[invalid.Key]; int before = transport.Calls;
            session[invalid.Key] = invalid.Value; Reject(reader,session, invalid.Key == "idToken" ? 401 : 403);
            Check(before == transport.Calls, "Invalid session reached network"); session[invalid.Key]=old;
        }
        JObject account=reader.LoadAsync(session).GetAwaiter().GetResult();
        Check(AcademicAccountReader.Display(account,"UniversityEmail") == "Not provided", "Invented institutional email");
        foreach(string field in new[] {"Name","Email","Major","PhoneNumber","ProfilePicUrl","UniversityEmail"}) {
            Check(AcademicAccountReader.Display(new JObject(),field)=="Not provided", "Missing field fabricated");
            Check(AcademicAccountReader.Display(new JObject {{field,"   "}},field)=="Not provided", "Empty field fabricated");
        }
        Check(HttpUtility.HtmlEncode(AcademicAccountReader.Display(account,"Name")).Contains("&lt;script&gt;"),"Encoding failed");
        transport.DenyIdentity=true; Reject(reader,session,401); transport.DenyIdentity=false;
        transport.Disabled=true; Reject(reader,session,401); transport.Disabled=false;
        transport.LocalId="another-supervisor"; Reject(reader,session,401); transport.LocalId="uid-fixture";
        session["idToken"]=Token("wrong-project"); Reject(reader,session,401);
        session["idToken"]=Token(expiry:DateTimeOffset.UtcNow.ToUnixTimeSeconds()-1); Reject(reader,session,401);
        session["idToken"]=Token(subject:"another-supervisor"); Reject(reader,session,401);
        session["idToken"]=Token(algorithm:"none"); Reject(reader,session,401);
        session["idToken"]="malformed"; Reject(reader,session,401); session["idToken"]=Token();
        transport.ValidSince=DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(); Reject(reader,session,401); transport.ValidSince="0";
        transport.Body="{\"Role\":\"CompanySupervisor\"}"; Reject(reader,session,403);
        transport.Body="null"; Reject(reader,session,404);
        transport.ReadStatus=HttpStatusCode.Forbidden; Reject(reader,session,403);
        transport.ReadStatus=HttpStatusCode.Unauthorized; Reject(reader,session,403);
        transport.ReadStatus=HttpStatusCode.InternalServerError; Reject(reader,session,503);
        BindingChecks();
        WriteChecks();
        Console.WriteLine("PASS: "+checks+" offline identity, ownership, field, encoding and HTTP assertions. No live Firebase calls.");
    }
}

'@
[IO.File]::WriteAllText((Join-Path $temporary 'Checks.cs'), $fixture)
$framework = 'C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8'
$refs = @('mscorlib.dll','System.dll','System.Core.dll','System.Web.dll','System.Net.Http.dll','System.Configuration.dll') | ForEach-Object { '/reference:' + (Join-Path $framework $_) }
$refs += '/reference:'+(Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll')
$output = Join-Path $temporary 'AcademicAccountChecks.dll'
& 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\Roslyn\csc.exe' /nologo /target:library /langversion:7.3 /nostdlib+ ('/out:'+$output) $refs (Join-Path $ProjectRoot 'Config\AppConfig.cs') (Join-Path $PSScriptRoot 'SupervisorAccount.aspx.cs') (Join-Path $PSScriptRoot 'SupervisorAccount.aspx.designer.cs') (Join-Path $temporary 'Checks.cs')
if ($LASTEXITCODE) { throw 'Academic account source compilation failed' }
[void][Reflection.Assembly]::LoadFrom((Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll'))
[void][Reflection.Assembly]::LoadFrom($output)
[AcademicProfileChecks]::Run()
$page = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'SupervisorAccount.aspx'))
$designer = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'SupervisorAccount.aspx.designer.cs'))
foreach ($required in @('MasterPageFile="~/Shared/Dashboard.Master"','Async="true"','EnableViewState="false"','CodeBehind="SupervisorAccount.aspx.cs"','Inherits="UniversityInternshipManagmentSystem.Academic.SupervisorAccount.SupervisorAccount"','ContentPlaceHolderID="HeadContent"','ContentPlaceHolderID="MainContent"')) {
 if (!$page.Contains($required)) { throw "Missing ASPX integration: $required" }
}
foreach ($control in [regex]::Matches($page,'<asp:(?!Content\b)(\w+)\s+ID="(\w+)"')) {
 $type=$control.Groups[1].Value; $id=$control.Groups[2].Value
 if ($designer -notmatch ("WebControls\."+[regex]::Escape($type)+"\s+"+[regex]::Escape($id)+";")) { throw "Designer mismatch: $id" }
}
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'SupervisorAccount.aspx.cs'))
if ($source -match 'FirebaseDb\.(Patch|Put|Post|Delete)|academic_test_001|OfficeLocation|\["email"\]|session\["role"\]\s*=|session\["dbRecordId"\]\s*=') { throw 'Forbidden fallback, privileged writer or identity mutation detected' }
foreach($required in @('RequireCsrf(AccountCsrf, Request.Form["AcademicAccountCsrf"])','await LoadAsync(session);','new HttpMethod("PATCH")','JToken.DeepEquals','Server.HtmlEncode','ValidatePassword','signInWithPassword')) {
 if(!$source.Contains($required)){throw "Missing account protection: $required"}
}
if($page -match 'ID="ddlMajor"|ID="txtEmail"'){throw 'Removed editable-form fields still present'}
Write-Output 'PASS: ASPX/master/designer integration, removed form fields, own-account write/read-back, CSRF and no-fallback checks.'
