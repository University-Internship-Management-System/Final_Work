param([string]$App = (Split-Path (Split-Path $PSScriptRoot)))
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $App 'bin\Newtonsoft.Json.dll')
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ContactService.cs')) + @'

namespace UniversityInternshipManagmentSystem.Config { public static class AppConfig { public static string DbUrl; } }
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
Add-Type -TypeDefinition $source -ReferencedAssemblies @('System.dll','System.Core.dll','System.Net.Http.dll','System.Configuration.dll',(Join-Path $App 'bin\Newtonsoft.Json.dll'))
$checks = [UniversityInternshipManagmentSystem.ContactModule.ContactTests]::Run()
Write-Output "$checks Contact offline validation/repository checks passed. Fake transport only; no live Firebase requests."
$page = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Contact.aspx'))
$code = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Contact.aspx.cs'))
foreach ($pattern in @('ViewStateUserKey','Guid.TryParseExact','LastAttempt','PendingId','Csrf.Value','repository.IsAvailable')) {
 if (!$code.Contains($pattern)) {throw "Missing page protection: $pattern"}
}
if (!$page.Contains('~/Shared/Public.Master') -or $page -match '<(html|head|body|form|nav|footer)\b') {throw 'Invalid shared layout integration'}
Write-Output '7 Contact layout/security source checks passed (not runtime browser tests).'
