param([string]$App = (Split-Path (Split-Path $PSScriptRoot)))
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $App 'bin\Newtonsoft.Json.dll')
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ContactService.cs')) + @'

namespace UniversityInternshipManagmentSystem.Config { public static class AppConfig { public static string DbUrl; public static string ApiKey; } }
namespace UniversityInternshipManagmentSystem.ContactModule {
 public sealed class FakeAuthorization : IContactBackendAuthorization {
  public bool ContactMessagesApproved {get;set;}
  public System.Threading.Tasks.Task<string> GetOAuthAccessTokenAsync() { return System.Threading.Tasks.Task.FromResult("fake-offline-token"); }
 }
 public sealed class FakeTransport : System.Net.Http.HttpMessageHandler {
  public int Calls; public string Mode = "echo";
  protected override async System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> SendAsync(System.Net.Http.HttpRequestMessage req, System.Threading.CancellationToken ct) {
   Calls++;
   if (req.RequestUri.AbsoluteUri != "https://team-test.firebaseio.com/ContactMessages/11111111111111111111111111111111.json") throw new System.Exception("Wrong endpoint");
   if (req.Headers.Authorization.Scheme != "Bearer" || req.Headers.Authorization.Parameter != "fake-offline-token") throw new System.Exception("Missing auth");
   if (!req.Headers.Contains("if-match") || req.Method != System.Net.Http.HttpMethod.Put) throw new System.Exception("Missing create-only guard");
   var body = await req.Content.ReadAsStringAsync();
   var parsed = Newtonsoft.Json.Linq.JObject.Parse(body);
   if (parsed.Count != 5 || parsed["CreatedUtc"] == null) throw new System.Exception("Unexpected schema");
   return new System.Net.Http.HttpResponseMessage(Mode == "denied" ? System.Net.HttpStatusCode.Forbidden : System.Net.HttpStatusCode.OK) {
    Content = new System.Net.Http.StringContent(Mode == "mismatch" ? "null" : body)
   };
  }
 }
 public sealed class FakeSession : System.Web.HttpSessionStateBase {
  private readonly System.Collections.Generic.Dictionary<string,object> values=new System.Collections.Generic.Dictionary<string,object>();
  public override object this[string key] {get{object value;return values.TryGetValue(key,out value)?value:null;}set{values[key]=value;}}
 }
 public sealed class SignedInTransport : System.Net.Http.HttpMessageHandler {
  public int Writes,Lookups;public bool RejectIdentity,Disabled,MismatchUid;public string Mode="echo",ValidSince="0";
  protected override async System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> SendAsync(System.Net.Http.HttpRequestMessage request,System.Threading.CancellationToken cancellation) {
   if(request.Method==System.Net.Http.HttpMethod.Post&&request.RequestUri.Host=="identitytoolkit.googleapis.com"&&request.RequestUri.AbsolutePath=="/v1/accounts:lookup") {
    Lookups++;
    var payload=Newtonsoft.Json.Linq.JObject.Parse(await request.Content.ReadAsStringAsync());
    if(payload.Count!=1||payload["idToken"]==null)throw new System.Exception("Lookup used an unexpected credential");
    return new System.Net.Http.HttpResponseMessage(RejectIdentity?System.Net.HttpStatusCode.BadRequest:System.Net.HttpStatusCode.OK){Content=new System.Net.Http.StringContent(new Newtonsoft.Json.Linq.JObject{{"users",new Newtonsoft.Json.Linq.JArray(new Newtonsoft.Json.Linq.JObject{{"localId",MismatchUid?"foreign":"fixture-uid"},{"disabled",Disabled},{"validSince",ValidSince}})}}.ToString())};
   }
   Writes++;
   if(request.Method!=System.Net.Http.HttpMethod.Put||request.RequestUri.Host!="team-test.firebaseio.com"||request.RequestUri.AbsolutePath!="/ContactMessages/11111111111111111111111111111111.json")throw new System.Exception("Unexpected database endpoint or collection read");
   if(request.Headers.Authorization!=null||string.IsNullOrEmpty(System.Web.HttpUtility.ParseQueryString(request.RequestUri.Query)["auth"]))throw new System.Exception("Sender token missing or administrator bearer substituted");
   if(!request.Headers.Contains("if-match"))throw new System.Exception("Create-only protection lost");
   var body=await request.Content.ReadAsStringAsync();var parsed=Newtonsoft.Json.Linq.JObject.Parse(body);
   if(parsed.Count!=5||parsed["CreatedUtc"]==null||parsed["Role"]!=null)throw new System.Exception("Unapproved schema");
   return new System.Net.Http.HttpResponseMessage(Mode=="denied"?System.Net.HttpStatusCode.Forbidden:Mode=="replay"?System.Net.HttpStatusCode.PreconditionFailed:System.Net.HttpStatusCode.OK){Content=new System.Net.Http.StringContent(Mode=="mismatch"?"null":body)};
  }
 }
 public static class SignedInChecks {
  private static int count;
  private static void Check(bool value,string label){if(!value)throw new System.Exception(label);count++;}
  private static string Encode(string value){return System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(value)).TrimEnd('=').Replace('+','-').Replace('/','_');}
  private static string Token(string project="team-test",long expiry=0,string subject="fixture-uid") {
   long now=System.DateTimeOffset.UtcNow.ToUnixTimeSeconds();
   return Encode("{\"alg\":\"RS256\"}")+"."+Encode(new Newtonsoft.Json.Linq.JObject{{"sub",subject},{"aud",project},{"iss","https://securetoken.google.com/"+project},{"exp",expiry==0?now+600:expiry},{"iat",now-10},{"auth_time",now-10}}.ToString())+".offline";
  }
  private static void Reject(System.Action action,string label){try{action();}catch(System.InvalidOperationException){count++;return;}catch(System.Net.Http.HttpRequestException){count++;return;}throw new System.Exception(label);}
  public static int Run(){
   var session=new FakeSession();var transport=new SignedInTransport();var http=new System.Net.Http.HttpClient(transport);
   var repo=new ContactRepository(session,http,"https://team-test.firebaseio.com/","offline-client-key");
   var message=new ContactMessage{FullName="Offline user",Email="fixture@example.invalid",Subject="Offline test",Message="Never sent to Firebase"};
   var id=System.Guid.Parse("11111111-1111-1111-1111-111111111111");
   Check(repo.SignInRequired&&!repo.IsAvailable,"Anonymous sender enabled");Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Anonymous sent");Check(transport.Lookups==0&&transport.Writes==0,"Anonymous reached network");
   session["userId"]="fixture-uid";session["role"]="student";session["idToken"]=Token();session["firstLogin"]=false;
   foreach(var role in new[]{"student","company","academic","coordinator"}){session["role"]=role;Check(repo.IsAvailable,"Valid team role rejected");}session["role"]="student";
   foreach(var entry in new System.Collections.Generic.Dictionary<string,object>{{"role","forged-role"},{"idToken",""},{"userId",""},{"firstLogin",true}}){var old=session[entry.Key];session[entry.Key]=entry.Value;Check(!repo.IsAvailable,"Invalid session enabled");Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Invalid session sent");session[entry.Key]=old;}
   Check(transport.Writes==0,"Invalid local session caused a database write");
   transport.RejectIdentity=true;Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Rejected Google identity accepted");transport.RejectIdentity=false;
   transport.Disabled=true;Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Disabled account accepted");transport.Disabled=false;
   transport.MismatchUid=true;Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Mismatched UID accepted");transport.MismatchUid=false;
   foreach(var token in new[]{Token("foreign-project"),Token(expiry:System.DateTimeOffset.UtcNow.ToUnixTimeSeconds()-1),Token(subject:"foreign-uid"),"malformed"}){session["idToken"]=token;Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Invalid token claims accepted");}session["idToken"]=Token();
   transport.ValidSince=System.DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Revoked token accepted");transport.ValidSince="0";
   Check(transport.Writes==0,"Unverified identity reached message collection");
   repo.SaveAsync(id,message).GetAwaiter().GetResult();Check(transport.Writes==1,"Verified sender could not save");
   foreach(var mode in new[]{"denied","replay","mismatch"}){transport.Mode=mode;Reject(()=>repo.SaveAsync(id,message).GetAwaiter().GetResult(),"Denied/duplicate/unconfirmed message reported success");}
   Check(!new ContactRepository(session,http,"https://team-test.firebaseio.com/",null).IsAvailable,"Missing team API configuration enabled");
   return count;
  }
 }
 public static class ContactTests {
  public static int Run() {
   int count=0;
   var m = new ContactMessage {FullName="Ahmad Ali",Email="student@example.com",Subject="Question",Message="Internship question & details"};
   if(ContactValidation.Validate(m).Count !=0) throw new System.Exception("Valid message rejected"); count++;
   foreach(var field in new[]{"FullName","Email","Subject","Message"}) {
    var p=typeof(ContactMessage).GetProperty(field); var original=p.GetValue(m);
    foreach(var bad in new[]{"", " ", "<script>alert(1)</script>", "abc\0def",new string('x',4001)}) {
     p.SetValue(m,bad); if(!ContactValidation.Validate(m).ContainsKey(field)) throw new System.Exception("Bad input accepted: "+field); count++;
    } p.SetValue(m,original);
   }
   foreach(var email in new[]{"invalid", "Name <x@example.com>", "a@localhost", "a@example.com\r\nBcc:x@example.com"}) {
    m.Email=email; if(!ContactValidation.Validate(m).ContainsKey("Email")) throw new System.Exception("Invalid email accepted"); count++;
   } m.Email="student@example.com";
   m.FullName=new string('a',100); m.Subject=new string('b',150); m.Message=new string('c',4000);
   if(ContactValidation.Validate(m).Count!=0) throw new System.Exception("Boundary rejected"); count++;
   var transport=new FakeTransport(); var http=new System.Net.Http.HttpClient(transport);
   var auth=new FakeAuthorization {ContactMessagesApproved=true};
   var id=System.Guid.Parse("11111111-1111-1111-1111-111111111111");
   foreach(var provider in new IContactBackendAuthorization[]{null,new FakeAuthorization()}) {
    var disabled=new ContactRepository(provider,http,"https://team-test.firebaseio.com/");
    try { disabled.SaveAsync(id,m).GetAwaiter().GetResult(); throw new System.Exception("Disabled repository sent"); }
    catch(System.InvalidOperationException) {count++;}
   }
   if(transport.Calls!=0) throw new System.Exception("Disabled network access"); count++;
   foreach(var url in new[]{"http://team-test.firebaseio.com/", "https://evil.example/", "https://team-test.firebaseio.com/wrong/", "https://team-test.firebaseio.com/?auth=x"}) {
    if(new ContactRepository(auth,http,url).IsAvailable) throw new System.Exception("Unsafe URL accepted"); count++;
   }
   var repo=new ContactRepository(auth,http,"https://team-test.firebaseio.com/");
   repo.SaveAsync(id,m).GetAwaiter().GetResult(); count++;
   foreach(var mode in new[]{"denied","mismatch"}) {
    transport.Mode=mode;
    try { repo.SaveAsync(id,m).GetAwaiter().GetResult(); throw new System.Exception("False success"); }
    catch(System.Net.Http.HttpRequestException) {count++;}
   }
   return count;
  }
 }
}
'@
$temporary=Join-Path $env:TEMP ('uims-contact-checks-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temporary)
$fixture=Join-Path $temporary 'Checks.cs'
[IO.File]::WriteAllText($fixture,$source)
$framework='C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8'
$refs=@('mscorlib.dll','System.dll','System.Core.dll','System.Net.Http.dll','System.Web.dll','System.Configuration.dll') | ForEach-Object { '/reference:'+(Join-Path $framework $_) }
$refs+='/reference:'+(Join-Path $App 'bin\Newtonsoft.Json.dll')
$output=Join-Path $temporary 'ContactChecks.dll'
& 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\Roslyn\csc.exe' /nologo /target:library /langversion:7.3 /nostdlib+ ('/out:'+$output) $refs $fixture
if($LASTEXITCODE){throw 'Contact source/offline fixture compilation failed'}
[void][Reflection.Assembly]::LoadFrom($output)
$checks = [UniversityInternshipManagmentSystem.ContactModule.ContactTests]::Run()
$checks += [UniversityInternshipManagmentSystem.ContactModule.SignedInChecks]::Run()
Write-Output "$checks Contact offline validation/repository checks passed. Fake transport only; no live Firebase requests."
$page = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Contact.aspx'))
$code = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Contact.aspx.cs'))
foreach ($pattern in @('ViewStateUserKey','Guid.TryParseExact','LastAttempt','PendingId','Csrf.Value','repository.IsAvailable','ContactRepository.ForSignedInUser','SignIn.NavigateUrl')) {
 if (!$code.Contains($pattern)) {throw "Missing page protection: $pattern"}
}
if (!$page.Contains('~/Shared/Public.Master') -or $page -match '<(html|head|body|form|nav|footer)\b') {throw 'Invalid shared layout integration'}
Write-Output '9 Contact layout/security source checks passed (not runtime browser tests).'
