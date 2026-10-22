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

public static class TraineesChecks
{
    private static int checks;
    private static void Check(bool value, string name) { if(!value) throw new Exception(name); checks++; }
    private static void Reject(Action action, string name) {
        try {action();} catch(UnauthorizedAccessException) {checks++; return;} catch(TraineesUnavailableException) {checks++;return;}
        throw new Exception(name);
    }
    private sealed class Session : HttpSessionStateBase {
        private readonly Dictionary<string,object> values = new Dictionary<string,object>();
        public override object this[string key] {get {object v; return values.TryGetValue(key,out v)?v:null;} set {values[key]=value;}}
    }
    private sealed class Context : HttpContextBase {
        private readonly Session session;
        public Context(Session value){session=value;}
        public override HttpSessionStateBase Session {get{return session;}}
    }
    private static string Encode(string text){return Convert.ToBase64String(Encoding.UTF8.GetBytes(text)).TrimEnd('=').Replace('+','-').Replace('/','_');}
    // Exercises the actual code-behind binding method without creating a login/session.
    private sealed class BindingPage : MyTraineesPage {
        public BindingPage() {
            TotalCount=new Label();CompanyName=new Label();SearchError=new Label();ResultCount=new Label();
            SearchInput=new TextBox();SearchButton=new Button();Trainees=new Repeater();
            UnavailableState=new Panel();EmptyState=new Panel();Feedback=new Panel();
            EmptyHeading=new Literal();EmptyText=new Literal();FeedbackText=new Literal();UnavailableHeading=new Literal();
        }
        public void Bind(IList<TraineeRow> rows,string search){SearchInput.Text=search;BindResults(rows);}
        public int Listed {get{return Trainees.Items.Count;}}
        public string Total {get{return TotalCount.Text;}}
        public string Heading {get{return EmptyHeading.Text;}}
        public bool Empty {get{return EmptyState.Visible;}}
        public bool Invalid {get{return SearchInput.Attributes["aria-invalid"]=="true";}}
        public string Search {get{return SearchInput.Text;}}
    }
    private static string Token(string audience="team-fixture", long expiry=0) {
        var now=DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var claims=new JObject { {"aud",audience},{"iss","https://securetoken.google.com/"+audience},{"sub","uid-fixture"},{"exp",expiry==0?now+300:expiry},{"iat",now-10},{"auth_time",now-10} };
        return Encode("{\"alg\":\"RS256\"}")+"."+Encode(claims.ToString())+".offline-fake-signature";
    }
    private sealed class Transport : HttpMessageHandler {
        public int Auth, Companies, Queries;
        public bool DenyAuth, DenyQuery, WrongScope;
        public JObject Company = JObject.Parse("{\"Role\":\"CompanySupervisor\",\"AuthUid\":\"uid-fixture\",\"CompanyName\":\"Offline Company\"}");
        public JObject People = JObject.Parse("{\"s1\":{\"Name\":\"<script>offline</script>\",\"Major\":\"Software\",\"UniEmail\":\"fixture@example.com\",\"CompanyId\":\"company-fixture\"},\"s2\":{\"Name\":\"Accepted only\",\"CompanyId\":\"company-fixture\"},\"s3\":{\"Name\":\"Unconfirmed\",\"CompanyId\":\"company-fixture\"}}");
        public JObject Apps = JObject.Parse("{\"a1\":{\"StudentId\":\"s1\",\"CompanyId\":\"company-fixture\",\"Status\":\"Confirmed\"},\"a2\":{\"StudentId\":\"s2\",\"CompanyId\":\"company-fixture\",\"Status\":\"Accepted\"},\"a3\":{\"StudentId\":\"s3\",\"CompanyId\":\"company-fixture\",\"Status\":\"Pending\"},\"a4\":{\"StudentId\":\"s3\",\"CompanyId\":\"company-fixture\",\"Status\":\"Rejected\"}}");
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage req,CancellationToken ct) {
            if(req.Method==HttpMethod.Post && req.RequestUri.Host=="identitytoolkit.googleapis.com" && req.RequestUri.AbsolutePath.EndsWith("accounts:lookup")) {
                Auth++; return Response(DenyAuth?HttpStatusCode.BadRequest:HttpStatusCode.OK,"{\"users\":[{\"localId\":\"uid-fixture\",\"disabled\":false,\"validSince\":\"0\"}]}");
            }
            if(req.Method!=HttpMethod.Get || req.RequestUri.Host!="team-fixture-default-rtdb.europe-west1.firebasedatabase.app" || req.RequestUri.Scheme!="https") throw new Exception("Unsafe transport request");
            if(req.RequestUri.AbsolutePath=="/CompanySupervisors/company-fixture.json"){Companies++;return Response(HttpStatusCode.OK,Company.ToString());}
            if(req.RequestUri.AbsolutePath!="/Students.json" && req.RequestUri.AbsolutePath!="/Applications.json") throw new Exception("Unexpected database path");
            var query=Uri.UnescapeDataString(req.RequestUri.Query);
            if(!query.Contains("&orderBy=\"CompanyId\"&equalTo=\"company-fixture\"")) throw new Exception("Unfiltered collection request");
            Queries++;
            if(DenyQuery)return Response(HttpStatusCode.Forbidden,"{\"error\":\"secret internal details\"}");
            if(WrongScope) return Response(HttpStatusCode.OK,"{\"foreign\":{\"CompanyId\":\"other-company\",\"Name\":\"Must not display\"}}");
            return Response(HttpStatusCode.OK,req.RequestUri.AbsolutePath=="/Students.json"?People.ToString():Apps.ToString());
        }
        private static Task<HttpResponseMessage> Response(HttpStatusCode code,string json){return Task.FromResult(new HttpResponseMessage(code){Content=new StringContent(json,Encoding.UTF8,"application/json")});}
    }
    public static string Run() {
        string normalized;
        Check(TraineesValidation.TrySearch(" Software ",out normalized)&&normalized=="Software","Trimmed search");
        foreach(var input in new[]{new string('x',101),"<script>","x\0y"}) Check(!TraineesValidation.TrySearch(input,out normalized),"Invalid search accepted");
        var session=new Session(); var context=new Context(session); var fake=new Transport();
        var repo=new MyTraineesRepository(new HttpClient(fake),"https://team-fixture-default-rtdb.europe-west1.firebasedatabase.app/","offline-public-key");
        Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Anonymous accepted");
        Check(fake.Auth==0&&fake.Companies==0&&fake.Queries==0,"Anonymous made network requests");
        session["userId"]="uid-fixture";session["idToken"]=Token();session["dbRecordId"]="company-fixture";session["dbTable"]="CompanySupervisors";session["role"]="company";
        foreach(var pair in new Dictionary<string,object>{{"role","student"},{"dbTable","Admins"},{"firstLogin",true},{"dbRecordId","../escape"},{"idToken",""}}){var old=session[pair.Key];session[pair.Key]=pair.Value;Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Invalid session accepted: "+pair.Key);session[pair.Key]=old;}
        var company=repo.VerifySupervisorAsync(context).GetAwaiter().GetResult();
        Check(company.RecordKey=="company-fixture"&&company.CompanyName=="Offline Company","Verified ownership failed");
        Reject(()=>repo.GetConfirmedTraineesAsync(company,null).GetAwaiter().GetResult(),"Missing approval accepted");
        Reject(()=>repo.GetConfirmedTraineesAsync(company,new MyTraineesReadApproval(true,false,false)).GetAwaiter().GetResult(),"Missing policy accepted");
        Check(fake.Queries==0,"Unapproved trainee queries occurred");
        var rows=repo.GetConfirmedTraineesAsync(company,new MyTraineesReadApproval(true,true,false)).GetAwaiter().GetResult();
        Check(rows.Count==1,"Pending/accepted/rejected or unassigned students exposed");
        Check(rows[0].Contact=="","Unapproved contact exposed");
        Check(HttpUtility.HtmlEncode(rows[0].Name).StartsWith("&lt;script&gt;"),"Unsafe text not encodable");
        Check(repo.GetConfirmedTraineesAsync(company,new MyTraineesReadApproval(true,true,true)).GetAwaiter().GetResult()[0].Contact=="fixture@example.com","Approved university email absent");
        var directory=new List<TraineeRow>(rows) {new TraineeRow{Name="Another fixture",Major="Computer Engineering",Contact=""}};
        using(var page=new BindingPage()){page.Bind(directory," SOFTWARE ");Check(page.Listed==1&&page.Total=="2","Major search or unfiltered count failed");}
        using(var page=new BindingPage()){page.Bind(directory,"ANOTHER");Check(page.Listed==1,"Case-insensitive name search failed");}
        using(var page=new BindingPage()){page.Bind(directory,"");Check(page.Listed==2&&!page.Empty,"Populated binding failed");}
        using(var page=new BindingPage()){page.Bind(directory,"No such fixture");Check(page.Listed==0&&page.Empty&&page.Heading=="No matching trainees","No-match state failed");}
        using(var page=new BindingPage()){page.Bind(new List<TraineeRow>(),"");Check(page.Empty&&page.Heading=="No confirmed trainees yet"&&page.Total=="0","Empty directory state failed");}
        using(var page=new BindingPage()){page.Bind(directory,"<script>");Check(page.Invalid&&page.Listed==0&&page.Search=="<script>"&&page.Heading=="Check your search","Validation lost input or exposed rows");}
        using(var page=new BindingPage()){page.Bind(directory,new string('x',101));Check(page.Invalid&&page.Listed==0,"Server length limit failed in binding");}
        fake.DenyQuery=true;try {repo.GetConfirmedTraineesAsync(company,new MyTraineesReadApproval(true,true,false)).GetAwaiter().GetResult();throw new Exception("Denied read succeeded");}catch(TraineesUnavailableException error){Check(!error.Message.Contains("secret"),"Sensitive error details exposed");}fake.DenyQuery=false;
        fake.WrongScope=true;Reject(()=>repo.GetConfirmedTraineesAsync(company,new MyTraineesReadApproval(true,true,false)).GetAwaiter().GetResult(),"Foreign company accepted");fake.WrongScope=false;
        fake.People=new JObject();fake.Apps=new JObject();Check(repo.GetConfirmedTraineesAsync(company,new MyTraineesReadApproval(true,true,false)).GetAwaiter().GetResult().Count==0,"Empty data fabricated");
        fake.Company["AuthUid"]="other-uid";Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Foreign supervisor accepted");fake.Company.Remove("AuthUid");Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Legacy email-only mapping accepted");
        Check(MyTraineesRepository.OwnsCompany(new JObject(),"same-uid","same-uid"),"UID-keyed mapping rejected");
        Check(!MyTraineesRepository.OwnsCompany(JObject.Parse("{\"AuthUid\":\"other\"}"),"same-uid","same-uid"),"Conflicting AuthUid ignored");
        fake.Company["AuthUid"]="uid-fixture";session["idToken"]=Token("other-project");Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Cross-project token accepted");
        session["idToken"]=Token("team-fixture",DateTimeOffset.UtcNow.ToUnixTimeSeconds()-1);Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Expired token accepted");
        fake.DenyAuth=true;session["idToken"]=Token();Reject(()=>repo.VerifySupervisorAsync(context).GetAwaiter().GetResult(),"Firebase-rejected token accepted");
        return "PASS: "+checks+" offline My Trainees checks. Fake transport only; no Firebase account or data request was made.";
    }
    public static string PopulatedFixture() {
        var transport=new Transport();
        return Newtonsoft.Json.JsonConvert.SerializeObject(MyTraineesRepository.SelectConfirmed(transport.People,transport.Apps,"company-fixture",true));
    }
}
'@
$fixturePath = Join-Path $temporary 'TraineesChecks.cs'
[IO.File]::WriteAllText($fixturePath,$fixture)
$output = Join-Path $temporary 'TraineesChecks.dll'
$framework='C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8'
$refs=@('mscorlib.dll','System.dll','System.Core.dll','System.Web.dll','System.Net.Http.dll','System.Xml.dll','System.Configuration.dll','System.Drawing.dll') | ForEach-Object {'/reference:'+(Join-Path $framework $_)}
$refs += '/reference:'+(Join-Path $ProjectRoot 'bin\UniversityInternshipManagmentSystem.dll')
$refs += '/reference:'+(Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll')
& $CompilerPath /nologo /target:library /langversion:7.3 /nostdlib+ ('/out:'+$output) $refs (Join-Path $PSScriptRoot 'MyTraineesRepository.cs') (Join-Path $PSScriptRoot 'MyTrainees.aspx.cs') (Join-Path $PSScriptRoot 'MyTrainees.aspx.designer.cs') $fixturePath
if($LASTEXITCODE){throw 'Independent module source compilation failed. The team project was not edited.'}
[void][Reflection.Assembly]::LoadFrom((Join-Path $ProjectRoot 'bin\Newtonsoft.Json.dll'))
[void][Reflection.Assembly]::LoadFrom((Join-Path $ProjectRoot 'bin\UniversityInternshipManagmentSystem.dll'))
[void][Reflection.Assembly]::LoadFrom($output)
[TraineesChecks]::Run()
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
Write-Output 'PASS: independent .NET Framework 4.8/C# 7.3 compilation; master, encoding, async directive, designer parity and search integration checks. Project registration and ASP.NET runtime compilation remain separate prerequisites.'

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
