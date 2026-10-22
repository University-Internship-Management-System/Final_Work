param(
    [string]$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')),
    [string]$CompilerPath = 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\Roslyn\csc.exe'
)
$ErrorActionPreference = 'Stop'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('uims-trainees-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporary | Out-Null
$fixture = @'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI.WebControls;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Company.MyTraineesModule;

public static class TraineesChecks {
    private static int checks;
    private static void Check(bool ok,string text){if(!ok)throw new Exception(text);Interlocked.Increment(ref checks);}
    private static void Reject(Action action,string text){try{action();}catch(UnauthorizedAccessException){Interlocked.Increment(ref checks);return;}catch(TraineesUnavailableException){Interlocked.Increment(ref checks);return;}throw new Exception(text);}
    private sealed class Session:HttpSessionStateBase {
        private Dictionary<string,object> values=new Dictionary<string,object>();
        public override object this[string key]{get{object v;return values.TryGetValue(key,out v)?v:null;}set{values[key]=value;}}
    }
    private sealed class Context:HttpContextBase { private Session session; public Context(Session s){session=s;} public override HttpSessionStateBase Session{get{return session;}} }
    private sealed class BindingPage:MyTraineesPage {
        public BindingPage(){TotalCount=new Label();CompanyName=new Label();SearchError=new Label();ResultCount=new Label();SearchInput=new TextBox();SearchButton=new Button();Trainees=new Repeater();UnavailableState=new Panel();EmptyState=new Panel();Feedback=new Panel();EmptyHeading=new Literal();EmptyText=new Literal();FeedbackText=new Literal();UnavailableHeading=new Literal();}
        public void Bind(IList<TraineeRow> rows,string query){SearchInput.Text=query;BindResults(rows);}
        public int Listed{get{return Trainees.Items.Count;}} public string Total{get{return TotalCount.Text;}}
        public bool Empty{get{return EmptyState.Visible;}} public string Heading{get{return EmptyHeading.Text;}}
        public bool Invalid{get{return SearchInput.Attributes["aria-invalid"]=="true";}} public string Search{get{return SearchInput.Text;}}
    }
    private static string Encode(string s){return Convert.ToBase64String(Encoding.UTF8.GetBytes(s)).TrimEnd('=').Replace('+','-').Replace('/','_');}
    // Synthetic token accepted ONLY by the in-memory fake transport, never a real server.
    private static string Token(string project="team-fixture",long expiry=0) {
        long now=DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        return Encode("{\"alg\":\"RS256\"}")+"."+Encode(new JObject{{"sub","uid-fixture"},{"aud",project},{"iss","https://securetoken.google.com/"+project},{"exp",expiry==0?now+600:expiry},{"iat",now-10},{"auth_time",now-10}}.ToString())+".offline";
    }
    private sealed class UnknownLengthContent:HttpContent {
        private readonly byte[] bytes;
        public UnknownLengthContent(string body){bytes=Encoding.UTF8.GetBytes(body);}
        protected override bool TryComputeLength(out long length){length=0;return false;}
        protected override Task SerializeToStreamAsync(System.IO.Stream stream,TransportContext context){return stream.WriteAsync(bytes,0,bytes.Length);}
        protected override Task<System.IO.Stream> CreateContentReadStreamAsync(){return Task.FromResult<System.IO.Stream>(new System.IO.MemoryStream(bytes));}
    }
    private sealed class Transport:HttpMessageHandler {
        public int Auth,StudentReads; public bool LargeApps,StreamingApps,MalformedApps,DenyAuth,DenyApps,DenyStudents,DenyTasks,DenySubmissions,WrongTaskScope,WrongApplicationScope;
        public JObject Company=JObject.Parse("{\"Role\":\"CompanySupervisor\",\"AuthUid\":\"uid-fixture\",\"CompanyName\":\"Offline Company\"}");
        public JObject Students=JObject.Parse("{\"s1\":{\"Name\":\"<script>offline</script>\",\"Major\":\"Software\",\"CompanyId\":\"company-fixture\",\"AcademicSupervisorId\":\"academic-fixture\"},\"s2\":{\"Name\":\"Accepted fixture\",\"Major\":\"Computer Engineering\",\"CompanyId\":\"\"},\"s5\":{\"Name\":\"Unassigned confirmation\",\"CompanyId\":\"\"},\"s6\":{\"Name\":\"Foreign assignment\",\"CompanyId\":\"another-company\"}}");
        public JObject Apps=JObject.Parse("{\"a1\":{\"StudentId\":\"s1\",\"CompanyId\":\"company-fixture\",\"Status\":\"Confirmed\",\"OpportunityTitle\":\"Recorded internship\",\"ConfirmedAt\":1700000000000},\"a2\":{\"StudentId\":\"s1\",\"CompanyId\":\"company-fixture\",\"Status\":\"Accepted\"},\"a3\":{\"StudentId\":\"s2\",\"CompanyId\":\"company-fixture\",\"Status\":\"Accepted\",\"OpportunityId\":\"opp-fixture\"},\"a4\":{\"StudentId\":\"s3\",\"CompanyId\":\"company-fixture\",\"Status\":\"Pending\"},\"a5\":{\"StudentId\":\"s4\",\"CompanyId\":\"company-fixture\",\"Status\":\"Rejected\"},\"a6\":{\"StudentId\":\"s5\",\"CompanyId\":\"company-fixture\",\"Status\":\"Confirmed\"},\"a7\":{\"StudentId\":\"s6\",\"CompanyId\":\"company-fixture\",\"Status\":\"Accepted\"}}");
        public JObject Tasks=JObject.Parse("{\"t1\":{\"CompanyId\":\"company-fixture\",\"WeekNumber\":1,\"StudentIds\":[\"s1\",\"s2\"]},\"t2\":{\"CompanyId\":\"company-fixture\",\"WeekNumber\":6,\"StudentIds\":[\"s1\"]},\"t7\":{\"CompanyId\":\"company-fixture\",\"WeekNumber\":7,\"StudentIds\":[\"s1\"]}}");
        public JObject Submissions=JObject.Parse("{\"v1\":{\"TaskId\":\"t1\",\"StudentId\":\"s1\",\"Version\":1,\"SubmittedAt\":\"2026-10-01T12:00:00Z\",\"Status\":\"Submitted\"},\"v2\":{\"TaskId\":\"t1\",\"StudentId\":\"s1\",\"Version\":2,\"SubmittedAt\":\"2026-10-02T12:00:00Z\",\"Status\":\"RevisionRequested\"},\"v3\":{\"TaskId\":\"t2\",\"StudentId\":\"s1\",\"Version\":1,\"SubmittedAt\":\"2026-10-01T12:00:00Z\",\"Status\":\"Evaluated\"},\"v4\":{\"TaskId\":\"t7\",\"StudentId\":\"s1\",\"Version\":1,\"SubmittedAt\":\"2026-10-01T12:00:00Z\",\"Status\":\"Evaluated\"}}");
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage req,CancellationToken ct){
            if(req.Method==HttpMethod.Post&&req.RequestUri.Host=="identitytoolkit.googleapis.com"){Interlocked.Increment(ref Auth);return Response(DenyAuth?HttpStatusCode.BadRequest:HttpStatusCode.OK,"{\"users\":[{\"localId\":\"uid-fixture\",\"disabled\":false,\"validSince\":\"0\"}]}");}
            Check(req.Method==HttpMethod.Get&&req.RequestUri.Scheme=="https"&&req.RequestUri.Host=="team-fixture-default-rtdb.europe-west1.firebasedatabase.app","Unsafe database transport");
            var query=HttpUtility.ParseQueryString(req.RequestUri.Query);Check(!string.IsNullOrEmpty(query["auth"]),"Token missing");
            var path=req.RequestUri.AbsolutePath;
            if(path=="/CompanySupervisors/company-fixture.json")return Response(HttpStatusCode.OK,Company.ToString());
            if(path=="/Applications.json"){
                Check(query["orderBy"]==null&&query["equalTo"]==null,"Applications still requires an index");
                if(LargeApps){var response=new HttpResponseMessage(HttpStatusCode.OK);response.Content=StreamingApps?(HttpContent)new UnknownLengthContent(new string('x',512*1024+1)):new StringContent(new string('x',512*1024+1));return Task.FromResult(response);}
                return Response(DenyApps?HttpStatusCode.Forbidden:HttpStatusCode.OK,MalformedApps?"[]":WrongApplicationScope?"{\"x\":{\"CompanyId\":\"another-company\",\"StudentId\":\"foreign-never-read\",\"Status\":\"Accepted\"}}":Apps.ToString());
            }
            if(path.StartsWith("/Students/")&&path.EndsWith(".json")){Interlocked.Increment(ref StudentReads);string key=path.Substring(10,path.Length-15);Check(key!="s3"&&key!="s4","Pending/rejected student fetched");return Response(DenyStudents?HttpStatusCode.Forbidden:HttpStatusCode.OK,Students[key]==null?"null":Students[key].ToString());}
            if(path=="/Opportunities/opp-fixture.json")return Response(HttpStatusCode.OK,"{\"CompanyId\":\"company-fixture\",\"Title\":\"Opportunity record title\"}");
            if(path=="/Tasks.json"){Check(query["orderBy"]=="\"CompanyId\""&&query["equalTo"]=="\"company-fixture\"","Unscoped task query");return Response(DenyTasks?HttpStatusCode.Forbidden:HttpStatusCode.OK,WrongTaskScope?"{\"x\":{\"CompanyId\":\"another-company\"}}":Tasks.ToString());}
            if(path=="/TaskSubmissions.json"){Check(query["orderBy"]=="\"StudentId\"","Unscoped submissions");string student=(string)JToken.Parse(query["equalTo"]);Check(student=="s1"||student=="s2","Foreign student query");var data=new JObject();if(student=="s1")data=(JObject)Submissions.DeepClone();return Response(DenySubmissions?HttpStatusCode.Forbidden:HttpStatusCode.OK,data.ToString());}
            throw new Exception("Unexpected path: "+path);
        }
        private static Task<HttpResponseMessage> Response(HttpStatusCode code,string body){return Task.FromResult(new HttpResponseMessage(code){Content=new StringContent(body,Encoding.UTF8,"application/json")});}
    }
    private static MyTraineesRepository Repo(Transport f){return new MyTraineesRepository(new HttpClient(f),"https://team-fixture-default-rtdb.europe-west1.firebasedatabase.app/","offline-key");}
    public static string Run(){
        var f=new Transport();var repo=Repo(f);var s=new Session();var context=new Context(s);
        Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Anonymous accepted");Check(f.Auth==0,"Anonymous reached auth");
        s["userId"]="uid-fixture";s["idToken"]=Token();s["role"]="company";s["dbRecordId"]="company-fixture";s["dbTable"]="CompanySupervisors";
        foreach(var pair in new Dictionary<string,object>{{"role","student"},{"dbTable","Admins"},{"firstLogin",true},{"dbRecordId","../escape"},{"idToken",""}}){var old=s[pair.Key];s[pair.Key]=pair.Value;Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Invalid session accepted");s[pair.Key]=old;}
        var company=repo.VerifySupervisorAsync(context).GetAwaiter().GetResult();Check(company.CompanyName=="Offline Company","Company verification failed");
        var rows=repo.GetTraineesAsync(company).GetAwaiter().GetResult();Check(rows.Count==2,"Eligibility/dedup failed");
        var confirmed=rows.Single(r=>r.Status=="Confirmed");var accepted=rows.Single(r=>r.Status=="Accepted");
        Check(confirmed.OpportunityTitle=="Recorded internship"&&confirmed.CompanyName=="Offline Company","Recorded training details lost");
        Check(accepted.StatusText.Contains("awaiting confirmation")&&accepted.ConfirmationDate=="Awaiting confirmation","Accepted treated as confirmed");
        Check(accepted.OpportunityTitle=="Opportunity record title","Opportunity enrichment failed");
        Check(confirmed.ConfirmationDate.Contains("UTC")&&confirmed.ConfirmationDate!="Not available","Confirmation timestamp lost");
        Check(confirmed.AssignedTasks==2&&confirmed.SubmittedTasks==1&&confirmed.EvaluatedTasks==1&&confirmed.TaskProgressPercent==50,"Latest version/MyProgress scope incorrect");
        Check(accepted.AssignedTasks==1&&accepted.SubmittedTasks==0&&accepted.TaskProgressPercent==0,"Empty submissions invented");
        Check(rows.All(r=>r.Contact==""),"Email disclosure expanded");
        using(var page=new BindingPage()){page.Bind(rows," SOFTWARE ");Check(page.Listed==1&&page.Total=="2","Major search/count failed");}
        using(var page=new BindingPage()){page.Bind(rows,"ACCEPTED");Check(page.Listed==1,"Name search failed");}
        using(var page=new BindingPage()){page.Bind(rows,"no match");Check(page.Empty&&page.Listed==0&&page.Heading=="No matching trainees","No-match state failed");}
        using(var page=new BindingPage()){page.Bind(new List<TraineeRow>(),"");Check(page.Empty&&page.Total=="0","Empty state failed");}
        using(var page=new BindingPage()){page.Bind(rows,"<script>");Check(page.Invalid&&page.Listed==0&&page.Search=="<script>","Invalid search unsafe/lost");}
        string normalized;Check(!TraineesValidation.TrySearch(new string('x',101),out normalized)&&!TraineesValidation.TrySearch("x\0y",out normalized),"Search limits failed");
        int before=f.StudentReads;
        f.LargeApps=true;Reject(()=>repo.GetTraineesAsync(company).GetAwaiter().GetResult(),"Oversized Content-Length accepted");Check(f.StudentReads==before,"Oversized response caused student reads");
        f.StreamingApps=true;Reject(()=>repo.GetTraineesAsync(company).GetAwaiter().GetResult(),"Oversized unknown-length stream accepted");Check(f.StudentReads==before,"Oversized stream caused student reads");f.LargeApps=f.StreamingApps=false;
        var savedApps=f.Apps;f.Apps=new JObject();for(int i=0;i<1001;i++)f.Apps["large"+i]=new JObject{{"CompanyId","foreign"}};
        Reject(()=>repo.GetTraineesAsync(company).GetAwaiter().GetResult(),"1000 record limit ignored");Check(f.StudentReads==before,"Too many records caused student reads");f.Apps=savedApps;
        f.MalformedApps=true;Reject(()=>repo.GetTraineesAsync(company).GetAwaiter().GetResult(),"Malformed root accepted");f.MalformedApps=false;
        f.DenyApps=true;Reject(()=>repo.GetTraineesAsync(company).GetAwaiter().GetResult(),"Denied applications accepted");f.DenyApps=false;
        f.DenyStudents=true;Reject(()=>repo.GetTraineesAsync(company).GetAwaiter().GetResult(),"Denied student read became empty");f.DenyStudents=false;
        before=f.StudentReads;f.WrongApplicationScope=true;Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().Count==0,"Foreign applications exposed");Check(f.StudentReads==before,"Foreign application caused a student read");f.WrongApplicationScope=false;
        f.Apps["foreign"]=new JObject{{"StudentId","foreign-never-read"},{"CompanyId","another-company"},{"Status","Accepted"},{"OpportunityTitle","Must never reach browser"}};
        Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().Count==2,"Mixed-company collection was not filtered");
        f.Apps.Remove("foreign");
        f.DenyTasks=true;Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().All(r=>!r.TaskProgressPercent.HasValue&&r.ProgressText=="Progress not available"),"Denied tasks fabricated progress");f.DenyTasks=false;
        f.WrongTaskScope=true;Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().All(r=>!r.TaskProgressPercent.HasValue),"Foreign tasks became progress");f.WrongTaskScope=false;
        f.DenySubmissions=true;Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().All(r=>!r.SubmittedTasks.HasValue),"Denied submissions became zero");f.DenySubmissions=false;
        f.Submissions["v2"]["Status"]=null;Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().Single(r=>r.Status=="Confirmed").TaskProgressPercent==null,"Missing status counted Submitted");f.Submissions["v2"]["Status"]="RevisionRequested";
        f.Company["AuthUid"]="foreign";Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Foreign owner accepted");f.Company.Remove("AuthUid");Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Email-only owner accepted");
        Check(MyTraineesRepository.OwnsCompany(new JObject(),"uid-fixture","uid-fixture"),"UID-keyed mapping rejected");f.Company["AuthUid"]="uid-fixture";
        s["idToken"]=Token("another-project");Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Cross-project token accepted");
        s["idToken"]=Token(expiry:DateTimeOffset.UtcNow.ToUnixTimeSeconds()-1);Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Expired token accepted");s["idToken"]=Token();
        f.DenyAuth=true;Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Rejected auth accepted");f.DenyAuth=false;
        var knownStudents=JObject.Parse("{\"student_test_001\":{\"CompanyId\":\"company_test_001\"}}");
        var knownApps=JObject.Parse("{\"app001\":{\"StudentId\":\"student_test_001\",\"CompanyId\":\"company_test_001\",\"Status\":\"Confirmed\",\"OpportunityId\":\"opp001\"}}");
        Check(MyTraineesRepository.SelectEligible(knownStudents,knownApps,"company_test_001","Orange Jordan").Count==1,"Known relationship failed");
        var originalTasks=f.Tasks;f.Tasks=new JObject();Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().All(r=>r.AssignedTasks==0&&r.TaskProgressPercent==0),"Successful empty task query unavailable or fabricated");f.Tasks=originalTasks;
        var missingStudent=(JObject)f.Students.DeepClone();f.Students.Remove("s2");Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().Count==1,"Missing Student record fabricated");f.Students=missingStudent;
        f.Apps=new JObject();Check(repo.GetTraineesAsync(company).GetAwaiter().GetResult().Count==0,"Empty applications fabricated students");
        return "PASS: "+checks+" offline identity, scoped read, eligibility, training, progress, search and error assertions. No live Firebase requests.";
    }
    public static string PopulatedFixture(){
        var f=new Transport();var rows=MyTraineesRepository.SelectEligible(f.Students,f.Apps,"company-fixture","Offline Company");
        foreach(var row in rows)MyTraineesRepository.ApplyProgress(row,f.Tasks.ToObject<Dictionary<string,UniversityInternshipManagmentSystem.Models.Tasks>>(),f.Submissions.Properties().Where(p=>(string)p.Value["StudentId"]==row.StudentKey).Aggregate(new JObject(),(a,p)=>{a[p.Name]=p.Value.DeepClone();return a;}));
        return Newtonsoft.Json.JsonConvert.SerializeObject(rows);
    }
}

'@
$fixturePath = Join-Path $temporary 'TraineesChecks.cs'
[IO.File]::WriteAllText($fixturePath,$fixture)
$output = Join-Path $temporary 'TraineesChecks.dll'
$framework='C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8'
$refs=@('mscorlib.dll','System.dll','System.Core.dll','System.Web.dll','System.Net.Http.dll','System.Xml.dll','System.Configuration.dll','System.Drawing.dll') | ForEach-Object {'/reference:'+(Join-Path $framework $_)}
$refs += '/reference:'+(Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll')
# Compile the minimal existing dependency sources rather than import the app DLL and
# redefine its module types (which previously generated CS0436 duplicate-type warnings).
$dependencySources=@('Config\AppConfig.cs','Config\AuthHelper.cs','Models\User.cs','Models\Student.cs','Models\CompanySupervisor.cs','Models\Application.cs','Models\Tasks.cs','Models\TaskSubmission.cs') | ForEach-Object { Join-Path $ProjectRoot $_ }
& $CompilerPath /nologo /target:library /langversion:7.3 /nostdlib+ ('/out:'+$output) $refs $dependencySources (Join-Path $PSScriptRoot 'MyTraineesRepository.cs') (Join-Path $PSScriptRoot 'MyTrainees.aspx.cs') (Join-Path $PSScriptRoot 'MyTrainees.aspx.designer.cs') $fixturePath
if($LASTEXITCODE){throw 'Independent module source compilation failed. The team project was not edited.'}
[void][Reflection.Assembly]::LoadFrom((Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll'))
[void][Reflection.Assembly]::LoadFrom($output)
[TraineesChecks]::Run()
$production=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'MyTraineesRepository.cs'))+[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'MyTrainees.aspx.cs'))
if($production -match 'MyTraineesReadApproval|Company.MyTrainees.ReadApproval'){throw 'Removed application-level gate still exists'}
if($production -match 'company_test_001|student_test_001|FirebaseDb\.(Put|Post|Patch|Delete)'){throw 'Hardcoded test IDs or database write in production'}
$page=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'MyTrainees.aspx'))
if($page -notmatch 'MasterPageFile="~/Shared/Dashboard.Master"' -or $page -notmatch 'HeadContent' -or $page -notmatch 'MainContent' -or $page -match '<(html|head|body|form|nav|footer)\b'){throw 'Shared layout integration invalid'}
if($page -notmatch '<%#: Eval' -or $page -notmatch 'Mode="Encode"'){throw 'Missing output encoding'}
$directive=[regex]::Match($page,'<%@ Page\b[^%]+%>').Value
foreach($required in @('Async="true"','AutoEventWireup="true"','CodeBehind="MyTrainees.aspx.cs"','Inherits="UniversityInternshipManagmentSystem.Company.MyTraineesModule.MyTraineesPage"')){
 if(!$directive.Contains($required)){throw "Missing Web Forms integration: $required"}
}
$designer=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'MyTrainees.aspx.designer.cs'))
$declared=@{}
foreach($declaration in [regex]::Matches($designer,'WebControls\.(\w+)\s+([^;]+);')){
 foreach($control in $declaration.Groups[2].Value.Split(',')){$declared[$control.Trim()]=$declaration.Groups[1].Value}
}
$markup=@{}
foreach($control in [regex]::Matches($page,'<asp:(?!Content\b)(\w+)\s+ID="(\w+)"')){$markup[$control.Groups[2].Value]=$control.Groups[1].Value}
if($declared.Count -ne $markup.Count){throw 'Designer/markup control counts differ'}
foreach($id in $markup.Keys){if($declared[$id] -ne $markup[$id]){throw "Designer type mismatch or missing control: $id"}}
if($page -notmatch 'DefaultButton="SearchButton"' -or $page -notmatch 'ValidateRequestMode="Disabled"'){throw 'Search postback/validation integration missing'}
Write-Output 'PASS: independent .NET Framework 4.8/C# 7.3 compilation; master, encoding, async directive, designer parity and search integration checks. Project registration and ASP.NET runtime compilation are verified separately; this does not prove Firebase access.'

# Render the actual ASPX ItemTemplate with existing offline fixture values only.
# This is a static visual artifact, not an alternate app or an authorization bypass.
$template=[regex]::Match($page,'<ItemTemplate>(.*?)</ItemTemplate>','Singleline').Groups[1].Value
$fixtureRows=@([TraineesChecks]::PopulatedFixture() | ConvertFrom-Json)
$items=@(foreach($fixtureRow in $fixtureRows){
 [regex]::Replace($template,'<%#: Eval\("(\w+)"\) %>',{param($match) [System.Web.HttpUtility]::HtmlEncode([string]$fixtureRow.($match.Groups[1].Value))})
}) -join ''
if($items -match '<%|<asp:|<script>' -or $items -notmatch '&lt;script&gt;offline&lt;/script&gt;'){throw 'Populated fixture template rendering/encoding failed'}
$styles=(@('Content/bootstrap.min.css','Shared/uims.css') | ForEach-Object {[IO.File]::ReadAllText((Join-Path $ProjectRoot $_))}) -join "`n"
$styles+="`n"+[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'MyTrainees.css'))
$fixtureHtml='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>My Trainees offline fixture</title><style>'+$styles+'</style></head><body style="padding:24px"><main class="trainees-page"><p role="note">OFFLINE TEST FIXTURE — NOT LIVE FIREBASE DATA. Actual ItemTemplate/CSS; shared master and runtime binding are not reproduced. Email disclosure is enabled only in this isolated test.</p><h1>My Trainees</h1><div class="card"><ul class="trainees-list">'+$items+'</ul></div></main></body></html>'
$fixtureOutput=Join-Path $temporary 'populated-fixture.html'
[IO.File]::WriteAllText($fixtureOutput,$fixtureHtml,(New-Object Text.UTF8Encoding($false)))
Write-Output "PASS: encoded populated ItemTemplate from existing fixtures. Visual artifact: $fixtureOutput"
