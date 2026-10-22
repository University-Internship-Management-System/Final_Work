param([string]$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')))
$ErrorActionPreference = 'Stop'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('uims-profile-phase1-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temporary)
$fixture = @'
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Reflection;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Student.StudentProfilePage;
using Student = UniversityInternshipManagmentSystem.Models.Student;

public static class ProfilePhase1Checks
{
    private static int checks;
    private static void Check(bool value, string name) { if (!value) throw new Exception(name); checks++; }
    private static void Reject(Action action, string name) {
        try { action(); } catch (UnauthorizedAccessException) { checks++; return; } catch (ArgumentException) { checks++; return; }
        throw new Exception(name);
    }
    private sealed class Harness : Profile {
        public Harness(Student record) {
            typeof(Page).GetField("_context",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,HttpContext.Current);
            typeof(Page).GetField("_request",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,HttpContext.Current.Request);
            typeof(Page).GetField("_response",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,HttpContext.Current.Response);
            EnableEventValidation = false; // Isolated control test only; production ASPX retains event validation.
            Workspace = record;
            foreach(var field in typeof(Profile).GetFields(BindingFlags.Instance|BindingFlags.NonPublic|BindingFlags.DeclaredOnly))
                if(typeof(Control).IsAssignableFrom(field.FieldType)) {
                    var control=(Control)Activator.CreateInstance(field.FieldType); control.ID=field.Name; field.SetValue(this,control); Controls.Add(control);
                }
            TrackViewState();
            Call("PrepareCandidateControls");
        }
        public object Call(string method) {
            try { return typeof(Profile).GetMethod(method,BindingFlags.Instance|BindingFlags.NonPublic).Invoke(this,null); }
            catch(TargetInvocationException e) { throw e.InnerException; }
        }
        public void Action(string name) {
            if(name=="edit") EditButton_Click(this,EventArgs.Empty);
            else if(name=="cancel") CancelButton_Click(this,EventArgs.Empty);
            else if(name=="save") SaveButton_Click(this,EventArgs.Empty);
            else ValidateButton_Click(this,EventArgs.Empty);
            Call("ProcessAction"); Call("ApplyPermissions");
        }
        public object State() { return SaveViewState(); }
        public void Restore(object state) { LoadViewState(state); }
        public bool Editing { get { return IsEditing; } }
        public bool SaveEnabled { get { return SaveButton.Enabled; } }
        public bool EditVisible { get { return EditButton.Visible; } }
        public bool CancelVisible { get { return CancelButton.Visible; } }
        public string Message { get { return SaveMessage.Text; } }
        public TextBox[] Inputs { get { return new[] { PhoneNumberInput,SkillsInput,CvInput,PortfolioInput }; } }
        public Label[] Errors { get { return new[] { PhoneError,SkillsError,CvError,PortfolioError }; } }
        public void Post(string phone, string skills, string cv, string portfolio) {
            var values=new[] {phone,skills,cv,portfolio};
            for(int i=0;i<Inputs.Length;i++) {
                var input=Inputs[i];
                var form=new NameValueCollection { { input.UniqueID,values[i] } };
                ((IPostBackDataHandler)input).LoadPostData(input.UniqueID,form);
            }
        }
    }
    private static Student Fixture() { return new Student {
        Name="Offline student", Email="fixture@example.invalid", UniEmail="fixture@university.invalid", Major="Recorded major", GPA=3.1,
        PhoneNumber="0791234567", SkillsList=new List<string>{"Original skill"}, CvUrl="https://example.invalid/original.pdf", PortfolioUrl=""
    }; }
    public static void Run() {
        // No network transport, real login, Firebase account, or database record is used.
        var context=new HttpContext(new HttpRequest("","http://localhost/",""),new HttpResponse(new System.IO.StringWriter()));
        HttpContext.Current=context;
        SessionStateUtility.AddHttpSessionStateToContext(context,new HttpSessionStateContainer("offline-profile-test",new SessionStateItemCollection(),
            new HttpStaticObjectsCollection(),20,true,HttpCookieMode.UseCookies,SessionStateMode.InProc,false));
        try {
            var record=Fixture();
            var view=new Harness(record); view.Call("ProcessAction"); view.Call("ApplyPermissions");
            Check(!view.Editing && view.EditVisible && !view.CancelVisible,"Initial view mode incorrect");
            foreach(var input in view.Inputs) Check(input.ReadOnly,"Initial field must be read-only");
            view.Action("edit");
            Check(view.Editing && !view.EditVisible && view.CancelVisible && !view.SaveEnabled,"Edit controls/policy incorrect");
            foreach(var input in view.Inputs) Check(!input.ReadOnly && !input.EnableViewState,"Candidate field cannot accept postback");
            object editState=view.State();
            var postback=new Harness(record); postback.Restore(editState);
            Check(postback.Editing,"Edit mode lost across ViewState restore");
            postback.Post("+962 791234567","C#\nSQL","www.example.com/cv","https://example.com/portfolio");
            Check(postback.Inputs[0].Text=="+962 791234567","New phone POST was ignored");
            Check(postback.Inputs[1].Text=="C#\nSQL","New multiline POST was ignored");
            Check(postback.Inputs[2].Text=="www.example.com/cv","New CV POST was ignored");
            Check(postback.Inputs[3].Text=="https://example.com/portfolio","New portfolio POST was ignored");
            postback.Action("validate");
            Check(postback.Message.Contains("passed validation") && postback.Message.Contains("Nothing was saved"),"Valid draft falsely reported saved");
            Check(!postback.SaveEnabled && record.PhoneNumber=="0791234567" && record.CvUrl=="https://example.invalid/original.pdf","Validation mutated stored profile");
            postback.Post("bad","toolong"+new string('x',60),"javascript:alert(1)","https://user:secret@example.com");
            postback.Action("validate");
            for(int i=0;i<4;i++) {
                Check(postback.Errors[i].Text.Length>0,"Missing field-level validation");
                Check(postback.Inputs[i].Attributes["aria-invalid"]=="true","Missing invalid-field accessibility");
            }
            Check(postback.Inputs[0].Text=="bad" && postback.Inputs[2].Text=="javascript:alert(1)","Invalid entries were overwritten");
            postback.Post("0799876543","Updated","https://example.com/new","https://example.com/p");
            postback.Action("save"); // Direct crafted event: still only validates a draft.
            Check(!postback.SaveEnabled && postback.Message.Contains("Nothing was saved") && record.PhoneNumber=="0791234567","Crafted Save enabled persistence");
            Check(record.Name=="Offline student" && record.Email=="fixture@example.invalid" && record.Major=="Recorded major" && record.GPA==3.1,"Academic identity changed");
            postback.Action("cancel");
            Check(!postback.Editing && postback.EditVisible && !postback.CancelVisible,"Cancel failed to exit editing");
            Check(postback.Inputs[0].Text==record.PhoneNumber && postback.Inputs[1].Text=="Original skill","Cancel did not restore authoritative values");
            foreach(var input in postback.Inputs) Check(input.ReadOnly,"Cancel left an editable field");
            Reject(()=>new Harness(record).Action("save"),"Save accepted without Edit");
            Reject(()=>new Harness(null).Action("edit"),"Missing profile accepted");
            var unavailable=new Harness(null); unavailable.Call("BindFields"); unavailable.Call("ApplyPermissions");
            Check(!unavailable.EditVisible && !unavailable.CancelVisible && unavailable.Inputs[0].Text=="","Unavailable profile controls leaked stale data");
            var missing=new Harness(new Student()); missing.Action("edit");
            foreach(var input in missing.Inputs) Check(input.Text=="","Missing field was fabricated");
            var csrf=new Harness(record);
            Reject(()=>csrf.Call("ValidateCsrf"),"Missing CSRF accepted");
            context.Session["Student.Csrf"]="offline-csrf";
            Reject(()=>csrf.Call("ValidateCsrf"),"Absent form CSRF accepted");
            var form=context.Request.Form;
            var readOnly=typeof(NameObjectCollectionBase).GetProperty("IsReadOnly",BindingFlags.Instance|BindingFlags.NonPublic);
            readOnly.SetValue(form,false,null); form["StudentCsrf"]="offline-csrf"; readOnly.SetValue(form,true,null);
            csrf.Call("ValidateCsrf"); checks++;
            readOnly.SetValue(form,false,null); form["StudentCsrf"]="wrong"; readOnly.SetValue(form,true,null);
            Reject(()=>csrf.Call("ValidateCsrf"),"Incorrect form CSRF accepted");

            foreach(var field in new[] {"Name","Email","UniEmail","Major","GPA","Role","AuthUid","CompanyId","AcademicSupervisorId"})
                Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object>{{field,"forged"}},ProfileValidation.EditableFields),"Overposting accepted");
            foreach(string url in new[] {"javascript:alert(1)","data:image/png;base64,xxx","https://u:p@example.com","https://example.com/"+new string('a',2048)})
                Reject(()=>ProfileValidation.NormalizeWebUrl(url),"Unsafe document URL accepted");
            Check(ProfileValidation.NormalizeWebUrl("www.example.com/cv")=="https://www.example.com/cv","Missing scheme normalization changed");
            Check(ProfileValidation.NormalizeWebUrl("http://example.com")=="http://example.com/","HTTP link support changed");
            Check(ProfileValidation.CreatePatch("","","","",ProfileValidation.EditableFields).Count==4,"Empty optional fields rejected");
            var imageMethod=typeof(Profile).GetMethod("SafeProfileImage",BindingFlags.Static|BindingFlags.NonPublic);
            foreach(string image in new[] {null,"","javascript:alert(1)","http://example.com/avatar","https://u:p@example.com/avatar"})
                Check(imageMethod.Invoke(null,new object[]{image})==null,"Unsafe avatar accepted");
            Check((string)imageMethod.Invoke(null,new object[]{"https://example.com/avatar"})=="https://example.com/avatar","Safe avatar rejected");
            Console.WriteLine("PASS: "+checks+" offline profile control/post-data, ViewState, Edit/Validate/Save/Cancel, CSRF, allowlist and URL checks. No Firebase operations.");
        } finally { HttpContext.Current=null; }
    }
}

'@
$fixturePath=Join-Path $temporary 'ProfileChecks.cs'
[IO.File]::WriteAllText($fixturePath,$fixture)
$framework='C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8'
$refs=@('mscorlib.dll','System.dll','System.Core.dll','System.Web.dll','System.Net.Http.dll') | ForEach-Object { '/reference:'+(Join-Path $framework $_) }
$assembly=Join-Path $ProjectRoot 'bin\UniversityInternshipManagmentSystem.dll'
$refs+='/reference:'+$assembly
$refs+='/reference:'+(Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll')
$output=Join-Path $temporary 'ProfilePhase1Checks.dll'
& 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\Roslyn\csc.exe' /nologo /target:library /langversion:7.3 /nostdlib+ ('/out:'+$output) $refs $fixturePath
if ($LASTEXITCODE) { throw 'Profile test compilation failed' }
[void][Reflection.Assembly]::LoadFrom((Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll'))
[void][Reflection.Assembly]::LoadFrom($assembly)
[void][Reflection.Assembly]::LoadFrom($output)
[ProfilePhase1Checks]::Run()
$page=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Profile.aspx'))
$designer=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Profile.aspx.designer.cs'))
foreach($required in @('MasterPageFile="~/Shared/Dashboard.Master"','Async="true"','CodeBehind="Profile.aspx.cs"','ContentPlaceHolderID="HeadContent"','ContentPlaceHolderID="MainContent"')) {
 if(!$page.Contains($required)){throw "Missing Web Forms integration: $required"}
}
foreach($control in [regex]::Matches($page,'<asp:(?!Content\b)(\w+)\s+ID="(\w+)"')) {
 $type=$control.Groups[1].Value; $id=$control.Groups[2].Value
 if($designer -notmatch ("WebControls\."+[regex]::Escape($type)+"\s+"+[regex]::Escape($id)+";")){throw "Designer mismatch: $id"}
}
foreach($section in @('Personal Information','Academic Information','Training Information','Skills &amp; Competencies','CV &amp; Professional Portfolio')) {
 if(!$page.Contains($section)){throw "Missing section: $section"}
}
foreach($control in @('Name','Email','UniEmail','Major','GPA','CompanyId','AcademicSupervisorId','AuthUid')) {
 if($page -match ('<asp:TextBox[^>]+ID="'+$control+'Input"')){throw "Academic/identity field is editable: $control"}
}
$code=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Profile.aspx.cs'))
if($code -match 'SaveProfileFieldsAsync\(|FirebaseDb\.(Patch|Put|Post|Delete)\('){throw 'Profile page contains a persistence call'}
if($code -notmatch 'CanUpdate => false'){throw 'Write policy is not disabled'}
if($page -match 'EnableEventValidation="false"|ValidateRequest="false"'){throw 'Production Web Forms protections disabled'}
Write-Output 'PASS: sections, shared master, designer parity, read-only identity and disabled persistence source checks.'
Write-Output 'Offline harness tests actual compiled controls/events and POST-data handling; it is not an authenticated HTTP/Firebase integration test.'
