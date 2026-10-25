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

public static class InboxPageChecks {
 static int checks;
 static void Check(bool value,string name){if(!value)throw new Exception(name);checks++;}
 sealed class Harness:ContactInboxPage {
  public List<ContactInboxRow> Rows;public int Reads;public bool Denied;
  public Harness(List<ContactInboxRow> rows){
   // Offline controls do not have a prior rendered __EVENTVALIDATION field. Production keeps event validation enabled.
   EnableEventValidation=false; Rows=rows;
   var flags=System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic;
   typeof(System.Web.UI.Page).GetField("_context",flags).SetValue(this,System.Web.HttpContext.Current);
   typeof(System.Web.UI.Page).GetField("_request",flags).SetValue(this,System.Web.HttpContext.Current.Request);
   typeof(System.Web.UI.Page).GetField("_response",flags).SetValue(this,System.Web.HttpContext.Current.Response);
   Workspace=new System.Web.UI.WebControls.Panel{ID="Workspace"};NoticePanel=new System.Web.UI.WebControls.Panel{ID="NoticePanel",Visible=false};EmptyPanel=new System.Web.UI.WebControls.Panel{ID="EmptyPanel",Visible=false};
   Notice=new System.Web.UI.WebControls.Literal();Summary=new System.Web.UI.WebControls.Literal();EmptyHeading=new System.Web.UI.WebControls.Literal();EmptyText=new System.Web.UI.WebControls.Literal();
   SearchInput=new System.Web.UI.WebControls.TextBox{ID="SearchInput"};Messages=new System.Web.UI.WebControls.Repeater{ID="Messages",EnableViewState=false};
   Controls.Add(Workspace);Controls.Add(NoticePanel);NoticePanel.Controls.Add(Notice);Workspace.Controls.Add(SearchInput);Workspace.Controls.Add(Summary);Workspace.Controls.Add(EmptyPanel);Workspace.Controls.Add(Messages);
   EmptyPanel.Controls.Add(EmptyHeading);EmptyPanel.Controls.Add(EmptyText);TrackViewState();
  }
  protected override Task<List<ContactInboxRow>> ReadInboxAsync(){Reads++;if(Denied)throw new InboxAccessException("Fixture access denied");return Task.FromResult(Rows);}
  public void LoadFixture(){LoadInboxAsync().GetAwaiter().GetResult();}
  public object State(){return SaveViewState();}
  public void Post(object state,string query){
   LoadViewState(state);
   typeof(System.Web.UI.Page).GetField("_requestValueCollection",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic).SetValue(this,new System.Collections.Specialized.NameValueCollection());
   var posted=new System.Collections.Specialized.NameValueCollection{{SearchInput.UniqueID,query}};
   ((System.Web.UI.IPostBackDataHandler)SearchInput).LoadPostData(SearchInput.UniqueID,posted);
  }
  public void Search(){Search_Click(this,EventArgs.Empty);LoadFixture();}
  public void Reload(){Reload_Click(this,EventArgs.Empty);LoadFixture();}
  public void Expire(){ViewState["ContactInbox.Session"]="different-session";}
  public int Count{get{return Messages.Items.Count;}}
  public bool Toolbar{get{return Workspace.Visible&&SearchInput.Visible;}}
  public bool Empty{get{return EmptyPanel.Visible;}}
  public bool NoticeVisible{get{return NoticePanel.Visible;}}
  public string SearchText{get{return SearchInput.Text;}}
  public string SummaryText{get{return Summary.Text;}}
 }
 public static void Run(){
  var context=new System.Web.HttpContext(new System.Web.HttpRequest("","http://localhost/",""),new System.Web.HttpResponse(new System.IO.StringWriter()));
  System.Web.HttpContext.Current=context;
  System.Web.SessionState.SessionStateUtility.AddHttpSessionStateToContext(context,new System.Web.SessionState.HttpSessionStateContainer("offline-inbox-session",new System.Web.SessionState.SessionStateItemCollection(),new System.Web.HttpStaticObjectsCollection(),20,true,System.Web.HttpCookieMode.UseCookies,System.Web.SessionState.SessionStateMode.InProc,false));
  try{
   var rows=new List<ContactInboxRow>{new ContactInboxRow{FullName="Offline Lujain",Email="lujain@example.invalid",Subject="Training question",Message="A unique message body"},new ContactInboxRow{FullName="Offline Rana",Email="rana@example.invalid",Subject="Supervisor access",Message="Other fixture"}};
   var first=new Harness(rows);first.LoadFixture();Check(first.Count==2&&first.Toolbar,"Initial messages/toolbar missing");object state=first.State();
   foreach(string query in new[]{"Lujain","LUJAIN@EXAMPLE","Training question","unique message","  Lujain  "}){
    var page=new Harness(rows);page.Post(state,query);Check(page.IsPostBack,"Fixture did not model a postback");page.Search();Check(page.Count==1&&page.Toolbar&&!page.NoticeVisible,"Matching search lost messages or toolbar: "+query);Check(page.Reads==1,"Search skipped protected repository boundary");
   }
   var none=new Harness(rows);none.Post(state,"not-a-match");none.Search();Check(none.Count==0&&none.Empty&&none.Toolbar&&!none.NoticeVisible,"No-match state removed search controls");
   var reload=new Harness(rows);reload.Post(state,"not-a-match");reload.Reload();Check(reload.Count==2&&reload.SearchText==""&&reload.Toolbar,"Reload did not clear search and restore messages");
   var empty=new Harness(new List<ContactInboxRow>());empty.LoadFixture();Check(empty.Toolbar&&empty.Empty&&empty.Count==0,"Empty inbox hid toolbar");
   var denied=new Harness(rows);denied.Post(state,"Lujain");denied.Denied=true;denied.Search();Check(denied.Toolbar&&denied.NoticeVisible&&denied.Count==0,"Read error hid the search toolbar or exposed stale results");
   var expired=new Harness(rows);expired.Post(state,"Lujain");expired.Expire();expired.Search();Check(expired.Reads==0&&expired.NoticeVisible&&expired.Toolbar&&expired.Count==0,"Expired form was not safely rejected");
   var longQuery=new Harness(rows);longQuery.Post(state,new string('x',101));longQuery.Search();Check(longQuery.Reads==0&&longQuery.NoticeVisible&&longQuery.Toolbar,"Oversized input was not safely rejected");
   Console.WriteLine("PASS: "+checks+" offline inbox page binding, posted search values, session-bound postbacks, Reload, empty/error and toolbar regression checks. No Firebase operations.");
  }finally{System.Web.HttpContext.Current=null;}
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
[InboxPageChecks]::Run()
$markup=Get-Content (Join-Path $PSScriptRoot 'ContactMessages.aspx') -Raw
foreach($field in @('FullName','Email','Subject','Message','DateLabel')) {
 if(!$markup.Contains('<%#: Eval("'+$field+'") %>')) { throw "Unencoded message field: $field" }
}
if(!$markup.Contains('MasterPageFile="~/Shared/Dashboard.Master"')) { throw 'Shared master missing' }
if(!$markup.Contains('Async="true"') -or !$markup.Contains('CodeFile="ContactMessages.aspx.cs"')) { throw 'ASPX async/codefile contract mismatch' }
if(!$source.Contains('ViewStateUserKey = Session.SessionID;') -or !$source.Contains('Response.Cache.SetNoStore();')) { throw 'Session/private cache protection missing' }
Write-Output 'PASS: encoded ASPX fields, shared master, async/CodeFile, session-bound postbacks and private-cache source checks. Runtime/browser checks are separate.'

if(!$markup.Contains('<asp:Repeater ID="Messages" runat="server" EnableViewState="false">')) { throw 'Message payload must not be retained in ViewState' }

if($markup.Contains('<asp:Panel ID="Workspace" runat="server" Visible="false">')) { throw 'Search controls must be available during the postback lifecycle' }
if(!$markup.Contains('DefaultButton="SearchButton"')) { throw 'Enter-to-search integration missing' }
