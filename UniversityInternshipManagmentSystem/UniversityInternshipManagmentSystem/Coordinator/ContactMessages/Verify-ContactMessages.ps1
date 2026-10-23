$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$json=Join-Path $root 'bin/Newtonsoft.Json.dll'
$assembly=Join-Path $root 'bin/UniversityInternshipManagmentSystem.dll'
[void][Reflection.Assembly]::LoadFrom($json)
[void][Reflection.Assembly]::LoadFrom($assembly)
$source=Get-Content (Join-Path $PSScriptRoot 'ContactMessages.aspx.cs') -Raw
$controls=@'
namespace UniversityInternshipManagmentSystem.Coordinator {
 public partial class ContactInboxPage {
  protected System.Web.UI.WebControls.Panel Workspace,NoticePanel,EmptyPanel;
  protected System.Web.UI.WebControls.Literal Notice,Summary,EmptyHeading,EmptyText;
  protected System.Web.UI.WebControls.TextBox SearchInput;
  protected System.Web.UI.WebControls.Repeater Messages;
 }
}
'@
$checks=@'
using System;
using System.Linq;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Coordinator;
public static class InboxChecks {
 static int count;
 static void Check(bool value,string name){if(!value)throw new Exception(name);count++;}
 static void Reject(Action action,string name){try{action();}catch(InboxAccessException){count++;return;}throw new Exception(name);}
 static string B64(string value){return Convert.ToBase64String(Encoding.UTF8.GetBytes(value)).TrimEnd('=').Replace('+','-').Replace('/','_');}
 static JObject Claims(){long now=DateTimeOffset.UtcNow.ToUnixTimeSeconds();return new JObject{{"sub","admin-uid"},{"aud","inbox-offline"},{"iss","https://securetoken.google.com/inbox-offline"},{"exp",now+900},{"iat",now-10},{"auth_time",now-10}};}
 static string Token(JObject claims,string alg="RS256"){return B64(new JObject{{"alg",alg}}.ToString())+"."+B64(claims.ToString())+".offline";}
 sealed class Transport:HttpMessageHandler {
  public int Auth,Admin,Inbox;public bool DenyAuth,Disabled,DenyAdmin,DenyInbox;public string LookupUid="admin-uid",ValidSince="0";
  public JObject Staff=new JObject{{"Role","Admin"},{"AuthUid","admin-uid"},{"Email","fixture@example.invalid"}};
  public JToken Data=new JObject{{"one",new JObject{{"FullName","Offline sender"},{"Email","sender@example.invalid"},{"Subject","Training question"},{"Message","Line one\nLine two"},{"CreatedUtc","2026-10-23T10:00:00Z"}}}};
  protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage r,CancellationToken cancel){
   if(r.RequestUri.Host=="identitytoolkit.googleapis.com"){
    Check(r.Method==HttpMethod.Post&&r.RequestUri.AbsolutePath=="/v1/accounts:lookup","Unexpected auth operation");Auth++;
    Check(JObject.Parse(r.Content.ReadAsStringAsync().Result)["idToken"]!=null,"Missing verification token");
    return Reply(DenyAuth?HttpStatusCode.Unauthorized:HttpStatusCode.OK,new JObject{{"users",new JArray(new JObject{{"localId",LookupUid},{"disabled",Disabled},{"validSince",ValidSince}})}});
   }
   Check(r.Method==HttpMethod.Get,"Inbox attempted a write");Check(r.RequestUri.Host=="inbox-offline-default-rtdb.firebaseio.com","Wrong database");
   Check(System.Web.HttpUtility.ParseQueryString(r.RequestUri.Query)["auth"]!=null,"Anonymous read");
   if(r.RequestUri.AbsolutePath=="/Admins/admin-key.json"){Admin++;return Reply(DenyAdmin?HttpStatusCode.Forbidden:HttpStatusCode.OK,Staff);}
   Check(r.RequestUri.AbsolutePath=="/ContactMessages.json","Unrelated record queried");Inbox++;return Reply(DenyInbox?HttpStatusCode.Forbidden:HttpStatusCode.OK,Data);
  }
  static Task<HttpResponseMessage> Reply(HttpStatusCode status,JToken data){return Task.FromResult(new HttpResponseMessage(status){Content=new StringContent(data.ToString())});}
 }
 static List<ContactInboxRow> Load(ContactInboxRepository repo,string token){return repo.LoadAsync("admin-uid","admin-key","Admins","coordinator",token).GetAwaiter().GetResult();}
 public static void Run(){
  var t=new Transport();using(var http=new HttpClient(t)){
   var repo=new ContactInboxRepository(http,"https://inbox-offline-default-rtdb.firebaseio.com/","offline-key");string token=Token(Claims());var rows=Load(repo,token);
   Check(rows.Count==1&&rows[0].Message=="Line one\nLine two","Message contract lost");Check(rows[0].DateLabel=="23 Oct 2026 10:00 UTC","Date incorrect");
   Check(t.Auth==1&&t.Admin==1&&t.Inbox==1,"Read order incorrect");
   foreach(string q in new[]{"offline","SENDER@EXAMPLE","Training","Line two",""})Check(ContactInboxRepository.Filter(rows,q).Count==1,"Search failed");
   Check(ContactInboxRepository.Filter(rows,"missing").Count==0,"Unrelated result returned");Reject(()=>ContactInboxRepository.Filter(rows,new string('x',101)),"Unbounded search");
   int before=t.Inbox;
   foreach(string role in new[]{"student","company","academic","admin","",null})Reject(()=>repo.LoadAsync("admin-uid","admin-key","Admins",role,token).GetAwaiter().GetResult(),"Nonstaff accepted");
   foreach(string key in new[]{"","../x","x/y","x%2fy","x?y","x.y","x\\y","x\ny",new string('x',129)})Reject(()=>repo.LoadAsync("admin-uid",key,"Admins","coordinator",token).GetAwaiter().GetResult(),"Unsafe key accepted");
   Reject(()=>repo.LoadAsync("admin-uid","admin-key","Students","coordinator",token).GetAwaiter().GetResult(),"Wrong table accepted");
   Reject(()=>Load(repo,"mock-token"),"Mock token accepted");Reject(()=>Load(repo,""),"Absent token accepted");Check(t.Inbox==before,"Invalid session read inbox");
   t.DenyAuth=true;Reject(()=>Load(repo,token),"Rejected identity accepted");t.DenyAuth=false;
   t.Disabled=true;Reject(()=>Load(repo,token),"Disabled user accepted");t.Disabled=false;
   t.LookupUid="foreign";Reject(()=>Load(repo,token),"UID mismatch accepted");t.LookupUid="admin-uid";
   foreach(string field in new[]{"sub","aud","iss"}){var c=Claims();c[field]="foreign";Reject(()=>Load(repo,Token(c)),"Foreign claim accepted");}
   foreach(string field in new[]{"exp","iat","auth_time"}){var c=Claims();c.Remove(field);Reject(()=>Load(repo,Token(c)),"Missing claim accepted");}
   var expired=Claims();expired["exp"]=0;Reject(()=>Load(repo,Token(expired)),"Expired token accepted");
   var future=Claims();future["iat"]=DateTimeOffset.UtcNow.ToUnixTimeSeconds()+600;Reject(()=>Load(repo,Token(future)),"Future token accepted");
   Reject(()=>Load(repo,Token(Claims(),"none")),"Unsigned alg accepted");t.ValidSince=DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();Reject(()=>Load(repo,token),"Revoked token accepted");t.ValidSince="0";
   t.Staff["AuthUid"]="foreign";Reject(()=>Load(repo,token),"Foreign owner accepted");t.Staff["AuthUid"]="admin-uid";
   t.Staff["Role"]="Student";Reject(()=>Load(repo,token),"Student record accepted");t.Staff["Role"]="Admin";Check(t.Inbox==before,"Invalid identity read inbox");
   t.DenyAdmin=true;Reject(()=>Load(repo,token),"Denied admin bypassed");t.DenyAdmin=false;t.DenyInbox=true;Reject(()=>Load(repo,token),"Denied inbox bypassed");t.DenyInbox=false;
   var byUid=new JObject{{"Role","Admin"}};Check(ContactInboxRepository.OwnsAdmin(byUid,"admin-uid","admin-uid"),"UID keyed admin rejected");Check(!ContactInboxRepository.OwnsAdmin(byUid,"email-key","admin-uid"),"Email mapping trusted");byUid["AuthUid"]="foreign";Check(!ContactInboxRepository.OwnsAdmin(byUid,"admin-uid","admin-uid"),"Conflicting mapping ignored");
   Check(ContactInboxRepository.Parse(JValue.CreateNull()).Count==0,"Null not empty");var missing=ContactInboxRepository.Parse(new JObject{{"empty",new JObject()}})[0];Check(missing.FullName=="Not provided"&&missing.DateLabel=="Date not provided","Missing data invented");
   Reject(()=>ContactInboxRepository.Parse(new JArray()),"Wrong structure accepted");Reject(()=>ContactInboxRepository.Parse(new JObject{{"bad",1}}),"Invalid row accepted");Reject(()=>ContactInboxRepository.Parse(new JObject{{"bad",new JObject{{"Message",new string('x',4001)}}}}),"Oversized message accepted");
   var huge=new JObject();for(int i=0;i<501;i++)huge[i.ToString()]=new JObject();Reject(()=>ContactInboxRepository.Parse(huge),"Huge collection accepted");
   var sorted=ContactInboxRepository.Parse(new JObject{{"old",new JObject{{"Subject","old"},{"CreatedUtc","2025-01-01T00:00:00Z"}}},{"new",new JObject{{"Subject","new"},{"CreatedUtc","2026-01-01T00:00:00Z"}}}});Check(sorted[0].Subject=="new","Sort failed");
   foreach(string url in new[]{"http://inbox-offline.firebaseio.com/","https://example.com/","https://u:p@inbox-offline.firebaseio.com/","https://inbox-offline.firebaseio.com/other","https://inbox-offline.firebaseio.com/?auth=x"})Reject(()=>new ContactInboxRepository(http,url,"offline-key"),"Unsafe config accepted");
  }
  Console.WriteLine("PASS: "+count+" offline inbox identity, authorization, read-only transport, schema, bounds, search and error checks. No live Firebase requests.");
 }
}
'@
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('uims-inbox-checks-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temporary)
$codeFiles=@((Join-Path $temporary 'Inbox.cs'),(Join-Path $temporary 'Controls.cs'),(Join-Path $temporary 'Checks.cs'))
[IO.File]::WriteAllText($codeFiles[0],$source)
[IO.File]::WriteAllText($codeFiles[1],$controls)
[IO.File]::WriteAllText($codeFiles[2],$checks)
$framework='C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8'
$refs=@('mscorlib.dll','System.dll','System.Core.dll','System.Web.dll','System.Net.Http.dll') | ForEach-Object { '/reference:'+(Join-Path $framework $_) }
$refs+='/reference:'+$assembly
$refs+='/reference:'+$json
$output=Join-Path $temporary 'InboxChecks.dll'
& 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\Roslyn\csc.exe' /nologo /target:library /langversion:7.3 /nostdlib+ ('/out:'+$output) $refs $codeFiles
if($LASTEXITCODE) { throw 'Inbox test compilation failed' }
[void][Reflection.Assembly]::LoadFrom($output)
[InboxChecks]::Run()
$markup=Get-Content (Join-Path $PSScriptRoot 'ContactMessages.aspx') -Raw
foreach($field in @('FullName','Email','Subject','Message','DateLabel')) {
 if(!$markup.Contains('<%#: Eval("'+$field+'") %>')) { throw "Unencoded message field: $field" }
}
if(!$markup.Contains('MasterPageFile="~/Shared/Dashboard.Master"')) { throw 'Shared master missing' }
if(!$markup.Contains('Async="true"') -or !$markup.Contains('CodeFile="ContactMessages.aspx.cs"')) { throw 'ASPX async/codefile contract mismatch' }
if(!$source.Contains('ViewStateUserKey = Session.SessionID;') -or !$source.Contains('Response.Cache.SetNoStore();')) { throw 'Session/private cache protection missing' }
Write-Output 'PASS: encoded ASPX fields, shared master, async/CodeFile, session-bound postbacks and private-cache source checks. Runtime/browser checks are separate.'

if(!$markup.Contains('<asp:Repeater ID="Messages" runat="server" EnableViewState="false">')) { throw 'Message payload must not be retained in ViewState' }
