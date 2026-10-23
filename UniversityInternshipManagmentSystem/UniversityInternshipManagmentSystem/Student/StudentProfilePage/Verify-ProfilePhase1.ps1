param([string]$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')))
$ErrorActionPreference = 'Stop'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('uims-profile-phase1-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temporary)
$fixture = @'
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Reflection;
using System.Linq;
using System.Threading.Tasks;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Student;
using Newtonsoft.Json.Linq;
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
        try { action(); } catch (UnauthorizedAccessException) { checks++; return; } catch (ArgumentException) { checks++; return; } catch (UniversityInternshipManagmentSystem.Student.StudentDataException) { checks++; return; }
        throw new Exception(name);
    }
    private sealed class Harness : Profile {
        public bool DenySave, IgnoreSave, DenyTraining;
        public int Saves;
        public IDictionary<string,object> SavedPatch;
        public JToken Applications=JValue.CreateNull();
        public Dictionary<string,JToken> Related=new Dictionary<string,JToken>();
        protected override Task PersistProfileAsync(IDictionary<string,object> patch) {
            Saves++; SavedPatch=patch;
            if(DenySave) throw new UniversityInternshipManagmentSystem.Student.StudentDataException("Firebase denied this operation.");
            if(!IgnoreSave) {
                Workspace.PhoneNumber=(string)patch["PhoneNumber"];Workspace.SkillsList=new List<string>((IList<string>)patch["SkillsList"]);
                Workspace.CvUrl=(string)patch["CvUrl"];Workspace.PortfolioUrl=(string)patch["PortfolioUrl"];if(patch.ContainsKey("LinkedInUrl"))Workspace.LinkedInUrl=(string)patch["LinkedInUrl"];
            }
            return Task.CompletedTask;
        }
        protected override Task<JToken> ReadProfileApplicationsAsync() {
            if(DenyTraining) throw new UnauthorizedAccessException("Offline permission denial");
            return Task.FromResult(Applications);
        }
        protected override Task<JToken> ReadTrainingRecordAsync(string path) {
            JToken value;if(DenyTraining||!Related.TryGetValue(path,out value))throw new UnauthorizedAccessException("Offline permission denial");
            return Task.FromResult(value);
        }
        public string Company {get{return CompanyText;}} public string Supervisor {get{return SupervisorText;}}
        public string Placement {get{return PlacementText;}} public string Opportunity {get{return OpportunityText;}}
        public string TrainingMessage {get{return TrainingNote;}}

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
            try { var result=typeof(Profile).GetMethod(method,BindingFlags.Instance|BindingFlags.NonPublic).Invoke(this,null); var task=result as Task; if(task!=null)task.GetAwaiter().GetResult(); return result; }
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
        public TextBox[] Inputs { get { return new[] { PhoneNumberInput,SkillsInput,CvInput,PortfolioInput,LinkedInInput }; } }
        public Label[] Errors { get { return new[] { PhoneError,SkillsError,CvError,PortfolioError,LinkedInError }; } }
        public void Post(string phone, string skills, string cv, string portfolio, string linkedIn="") {
            var values=new[] {phone,skills,cv,portfolio,linkedIn};
            for(int i=0;i<Inputs.Length;i++) {
                var input=Inputs[i];
                var form=new NameValueCollection { { input.UniqueID,values[i] } };
                ((IPostBackDataHandler)input).LoadPostData(input.UniqueID,form);
            }
        }
    }
    private sealed class AdapterHarness:Profile {
        public AdapterHarness(){
            typeof(Page).GetField("_context",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,HttpContext.Current);
            typeof(Page).GetField("_request",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,HttpContext.Current.Request);
            typeof(Page).GetField("_response",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,HttpContext.Current.Response);
            typeof(StudentPage).GetField("requestAllowed",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(this,true);
        }
        public Task Save(IDictionary<string,object> patch){return SaveProfileFieldsAsync(patch);}
    }
    private static string B64(string s){return Convert.ToBase64String(Encoding.UTF8.GetBytes(s)).TrimEnd('=').Replace('+','-').Replace('/','_');}
    private sealed class AdapterTransport:HttpMessageHandler {
        public int Writes; public bool Denied, IgnoreWrite, RejectIdentity;
        public JObject Record=new JObject{{"Role","Student"},{"Name","Offline student"},{"Email","fixture@example.invalid"},{"Major","Recorded major"},{"AuthUid","student-fixture"}};
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,CancellationToken cancellation){
            if(request.Method==HttpMethod.Post&&request.RequestUri.Host=="identitytoolkit.googleapis.com"&&request.RequestUri.AbsolutePath=="/v1/accounts:lookup")
                return Reply(RejectIdentity?HttpStatusCode.BadRequest:HttpStatusCode.OK,new JObject{{"users",new JArray(new JObject{{"localId","student-fixture"},{"disabled",false},{"validSince","0"}})}});
            Check(request.RequestUri.Host=="offline-profile-default-rtdb.firebaseio.com"&&request.RequestUri.AbsolutePath=="/Students/student-fixture.json","Adapter queried foreign database/record");
            Check(!string.IsNullOrEmpty(HttpUtility.ParseQueryString(request.RequestUri.Query)["auth"]),"Adapter omitted authenticated token");
            if(request.Method==HttpMethod.Get)return Reply(HttpStatusCode.OK,Record);
            Check(request.Method.Method=="PATCH","Adapter used unexpected mutation method");Writes++;
            var sent=JObject.Parse(request.Content.ReadAsStringAsync().GetAwaiter().GetResult());
            Check(sent.Count==5&&sent.Properties().All(x=>ProfileValidation.EditableFields.Contains(x.Name)),"Adapter overposted academic/identity fields");
            if(!Denied&&!IgnoreWrite)foreach(var field in sent.Properties())Record[field.Name]=field.Value.DeepClone();
            return Reply(Denied?HttpStatusCode.Forbidden:HttpStatusCode.OK,sent);
        }
        private static Task<HttpResponseMessage> Reply(HttpStatusCode code,JToken data){return Task.FromResult(new HttpResponseMessage(code){Content=new StringContent(data.ToString())});}
    }
    private static void AdapterChecks(){
        // Redirect the actual shared adapter to an in-memory handler in THIS test process only.
        // No production files/configuration/session or real Firebase transport are changed.
        var field=typeof(StudentPage).GetField("Client",BindingFlags.Static|BindingFlags.NonPublic);
        var previous=field.GetValue(null);string db=AppConfig.DbUrl,key=AppConfig.ApiKey;
        var session=HttpContext.Current.Session;var names=new[]{"userId","dbRecordId","dbTable","idToken"};var old=names.Select(x=>session[x]).ToArray();
        var handler=new AdapterTransport();using(var client=new HttpClient(handler))try{
            field.SetValue(null,client);AppConfig.DbUrl="https://offline-profile-default-rtdb.firebaseio.com/";AppConfig.ApiKey="offline-client-key";
            long now=DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            session["userId"]=session["dbRecordId"]="student-fixture";session["dbTable"]="Students";
            session["idToken"]=B64("{\"alg\":\"RS256\"}")+"."+B64(new JObject{{"sub","student-fixture"},{"aud","offline-profile"},{"iss","https://securetoken.google.com/offline-profile"},{"exp",now+600},{"iat",now-10},{"auth_time",now-10}}.ToString())+".offline";
            var patch=ProfileValidation.CreatePatch("0791234567","C#\nSQL","https://example.invalid/cv","https://example.invalid/portfolio",ProfileValidation.EditableFields,"https://www.linkedin.com/in/offline-test");
            var adapter=new AdapterHarness();adapter.Save(patch).GetAwaiter().GetResult();
            Check(handler.Writes==1&&ProfileValidation.MatchesPatch(adapter.Workspace,patch),"Actual adapter failed PATCH/read-back");
            var extra=new Dictionary<string,object>(patch){{"Role","Admin"}};int before=handler.Writes;
            Reject(()=>adapter.Save(extra).GetAwaiter().GetResult(),"Actual adapter accepted overposting");Check(handler.Writes==before,"Overposting reached adapter transport");
            handler.Record["AuthUid"]="foreign";Reject(()=>adapter.Save(patch).GetAwaiter().GetResult(),"Actual adapter ignored ownership mismatch");Check(handler.Writes==before,"Foreign UID reached PATCH");handler.Record["AuthUid"]="student-fixture";
            handler.RejectIdentity=true;Reject(()=>adapter.Save(patch).GetAwaiter().GetResult(),"Rejected Firebase identity reached save");Check(handler.Writes==before,"Rejected identity reached PATCH");handler.RejectIdentity=false;
            handler.Denied=true;Reject(()=>adapter.Save(patch).GetAwaiter().GetResult(),"Actual denied PATCH reported success");handler.Denied=false;
            handler.IgnoreWrite=true;patch["PhoneNumber"]="0799999999";Reject(()=>adapter.Save(patch).GetAwaiter().GetResult(),"Actual adapter skipped persistence verification");
        }finally{field.SetValue(null,previous);AppConfig.DbUrl=db;AppConfig.ApiKey=key;for(int i=0;i<names.Length;i++)session[names[i]]=old[i];}
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
            Check(view.Editing && !view.EditVisible && view.CancelVisible && view.SaveEnabled,"Edit controls/policy incorrect");
            foreach(var input in view.Inputs) Check(!input.ReadOnly && !input.EnableViewState,"Candidate field cannot accept postback");
            object editState=view.State();
            var postback=new Harness(record); postback.Restore(editState);
            Check(postback.Editing,"Edit mode lost across ViewState restore");
            postback.Post("+962 791234567","C#\nSQL","www.example.com/cv","https://example.com/portfolio","www.linkedin.com/in/edited-student");
            Check(postback.Inputs[0].Text=="+962 791234567","New phone POST was ignored");
            Check(postback.Inputs[1].Text=="C#\nSQL","New multiline POST was ignored");
            Check(postback.Inputs[2].Text=="www.example.com/cv","New CV POST was ignored");
            Check(postback.Inputs[3].Text=="https://example.com/portfolio","New portfolio POST was ignored");
            Check(postback.Inputs[4].Text=="www.linkedin.com/in/edited-student","LinkedIn POST was ignored");
            postback.Action("validate");
            Check(postback.Message.Contains("passed validation") && postback.Message.Contains("Nothing was saved"),"Valid draft falsely reported saved");
            Check(postback.SaveEnabled && record.PhoneNumber=="0791234567" && record.CvUrl=="https://example.invalid/original.pdf","Validation mutated stored profile");
            postback.Post("bad","toolong"+new string('x',60),"javascript:alert(1)","https://user:secret@example.com","https://linkedin.com.evil.invalid/in/test");
            postback.Action("validate");
            for(int i=0;i<5;i++) {
                Check(postback.Errors[i].Text.Length>0,"Missing field-level validation");
                Check(postback.Inputs[i].Attributes["aria-invalid"]=="true","Missing invalid-field accessibility");
            }
            Check(postback.Inputs[0].Text=="bad" && postback.Inputs[2].Text=="javascript:alert(1)","Invalid entries were overwritten");
            postback.Post("0799876543","Updated","https://example.com/new","https://example.com/p","https://www.linkedin.com/in/saved-student");
            context.Session["Student.Csrf"]="save-csrf";
            var postedForm=context.Request.Form;
            var formLock=typeof(NameObjectCollectionBase).GetProperty("IsReadOnly",BindingFlags.Instance|BindingFlags.NonPublic);
            formLock.SetValue(postedForm,false,null);postedForm["StudentCsrf"]="save-csrf";formLock.SetValue(postedForm,true,null);
            postback.DenySave=true;
            Reject(()=>postback.Action("save"),"Denied Firebase write reported success");
            Check(postback.Editing&&postback.Inputs[0].Text=="0799876543"&&record.PhoneNumber=="0791234567","Denied save lost draft or changed stored fields");
            postback.DenySave=false;postback.IgnoreSave=true;
            Reject(()=>postback.Action("save"),"Unconfirmed persistence reported success");postback.IgnoreSave=false;
            postback.Action("save");
            Check(!postback.Editing&&!postback.SaveEnabled&&postback.Message.Contains("saved and verified")&&record.PhoneNumber=="0799876543","Save/read-back did not exit editing");
            Check(postback.SavedPatch.Count==5&&!postback.SavedPatch.ContainsKey("Name")&&!postback.SavedPatch.ContainsKey("CompanyId"),"Save allowlist expanded");
            Check(record.LinkedInUrl=="https://www.linkedin.com/in/saved-student" && record.PortfolioUrl=="https://example.com/p","LinkedIn overwrote portfolio or failed read-back");
            Check(record.Name=="Offline student" && record.Email=="fixture@example.invalid" && record.Major=="Recorded major" && record.GPA==3.1,"Academic identity changed");
            postback.Action("edit");postback.Post("0790000000","Unsaved","","");postback.Action("cancel");
            Check(!postback.Editing && postback.EditVisible && !postback.CancelVisible,"Cancel failed to exit editing");
            Check(postback.Inputs[0].Text==record.PhoneNumber && postback.Inputs[1].Text=="Updated","Cancel did not restore authoritative values");
            Check(postback.Inputs[4].Text==record.LinkedInUrl,"Cancel failed to restore LinkedIn");
            foreach(var input in postback.Inputs) Check(input.ReadOnly,"Cancel left an editable field");
            postback.Action("edit");postback.Action("save");
            Check(!postback.SavedPatch.ContainsKey("LinkedInUrl") && record.LinkedInUrl=="https://www.linkedin.com/in/saved-student","Unchanged LinkedIn disrupted existing four-field saves");
            postback.Action("edit");postback.Post(record.PhoneNumber,"Updated",record.CvUrl,record.PortfolioUrl,"");postback.Action("save");
            Check(record.LinkedInUrl=="" && record.PortfolioUrl=="https://example.com/p","Clearing LinkedIn failed or changed portfolio");
            context.Session.Remove("Student.Csrf");
            formLock.SetValue(postedForm,false,null);postedForm.Remove("StudentCsrf");formLock.SetValue(postedForm,true,null);
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
            foreach(string link in new[] {"http://www.linkedin.com/in/test","https://linkedin.com.evil.invalid/in/test","https://evil-linkedin.com","javascript:alert(1)","https://user:pass@www.linkedin.com/in/test","https://www.linkedin.com/"+new string('x',2048),"https://www.linkedin.com/in/test\n"})
                Reject(()=>ProfileValidation.NormalizeLinkedInUrl(link),"Unsafe or foreign LinkedIn URL accepted");
            Check(ProfileValidation.NormalizeLinkedInUrl("www.linkedin.com/in/test")=="https://www.linkedin.com/in/test","LinkedIn scheme normalization failed");
            Check(ProfileValidation.GetSafeLinkedInUrl("https://evil.invalid")==null,"Unsafe stored LinkedIn link rendered");
            Check(ProfileValidation.NormalizeLinkedInUrl("")=="","Optional LinkedIn cannot be cleared");
            var linkedinPatch=ProfileValidation.CreatePatch("","","","",ProfileValidation.EditableFields,"https://www.linkedin.com/in/test");
            Check(linkedinPatch.Count==5 && (string)linkedinPatch["PortfolioUrl"]=="","LinkedIn patch replaced portfolio");
            Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object>{{"LinkedInUrl","https://evil.invalid"}},ProfileValidation.EditableFields),"LinkedIn transport validation bypassed");
            Reject(()=>ProfileValidation.ValidatePatch(new Dictionary<string,object>{{"LinkedInUrl","https://www.linkedin.com/in/test"}},new HashSet<string>{"PortfolioUrl"}),"Unauthorized LinkedIn field accepted");
            Check(!ProfileValidation.MatchesPatch(new Student{LinkedInUrl="https://www.linkedin.com/in/other"},new Dictionary<string,object>{{"LinkedInUrl","https://www.linkedin.com/in/test"}}),"LinkedIn read-back mismatch accepted");
            var imageMethod=typeof(Profile).GetMethod("SafeProfileImage",BindingFlags.Static|BindingFlags.NonPublic);
            foreach(string image in new[] {null,"","javascript:alert(1)","http://example.com/avatar","https://u:p@example.com/avatar"})
                Check(imageMethod.Invoke(null,new object[]{image})==null,"Unsafe avatar accepted");
            Check((string)imageMethod.Invoke(null,new object[]{"https://example.com/avatar"})=="https://example.com/avatar","Safe avatar rejected");
            var trainingRecord=Fixture();trainingRecord.CompanyId="company-fixture";trainingRecord.AcademicSupervisorId="academic-fixture";
            var training=new Harness(trainingRecord);
            training.Applications=JObject.Parse("{\"app\":{\"Status\":\"Confirmed\",\"CompanyId\":\"company-fixture\",\"OpportunityId\":\"opp-fixture\",\"ConfirmedAt\":1700000000000}}");
            training.Related["CompanySupervisors/company-fixture"]=new JObject{{"Role","CompanySupervisor"},{"CompanyName","Recorded company"}};
            training.Related["AcademicSupervisors/academic-fixture"]=new JObject{{"Role","AcademicSupervisor"},{"Name","Recorded supervisor"}};
            training.Related["Opportunities/opp-fixture"]=new JObject{{"CompanyId","company-fixture"},{"Title","Recorded opportunity"}};
            training.Call("LoadTrainingInfoAsync");
            Check(training.Company=="Recorded company"&&training.Supervisor=="Recorded supervisor"&&training.Placement=="Confirmed"&&training.Opportunity=="Recorded opportunity","Related training data was not displayed");
            training.Related["Opportunities/opp-fixture"]["CompanyId"]="foreign";training.Call("LoadTrainingInfoAsync");
            Check(training.Opportunity=="Not available","Foreign-company opportunity disclosed");
            training.DenyTraining=true;training.Call("LoadTrainingInfoAsync");
            Check(training.TrainingMessage.Contains("unavailable")&&training.Opportunity=="Not available","Denied training invented data or erased profile");
            var unassigned=new Harness(Fixture());unassigned.Applications=new JObject{{"app",new JObject{{"Status","Accepted"},{"CompanyId","offering-company"}}}};
            unassigned.Call("LoadTrainingInfoAsync");Check(unassigned.Placement.Contains("awaiting confirmation"),"Acceptance treated as confirmed placement");
            AdapterChecks();
            Console.WriteLine("PASS: "+checks+" offline profile control/post-data, ViewState, Edit/Validate/Save/Cancel, denied/unconfirmed saves, related training, CSRF, allowlist and URL checks. No Firebase operations.");
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
if(!$code.Contains('protected virtual Task PersistProfileAsync(IDictionary<string, object> patch) => SaveProfileFieldsAsync(patch)')){throw 'Profile does not use the existing verified write/read-back adapter'}
if($code -match 'CanUpdate => false|FirebaseDb\.(Patch|Put|Post|Delete)\('){throw 'Profile remains disabled or bypasses the verified adapter'}
foreach($required in @('ValidateCsrf();','ProfileValidation.EditableFields','ProfileValidation.MatchesPatch(Workspace, patch)','ReadOwnApplicationsAsync()')) {
 if(!$code.Contains($required)){throw "Missing profile safeguard: $required"}
}
if($page -match 'EnableEventValidation="false"|ValidateRequest="false"'){throw 'Production Web Forms protections disabled'}
Write-Output 'PASS: sections, shared master, designer parity, read-only identity, verified save adapter and related-data source checks.'
Write-Output 'Offline checks exercise page controls and the actual shared adapter against an in-memory HTTP handler. They do not prove live Firebase access.'
