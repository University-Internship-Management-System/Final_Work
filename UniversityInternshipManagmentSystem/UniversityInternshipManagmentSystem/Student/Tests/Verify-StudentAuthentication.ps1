$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$assembly = Join-Path $root 'bin/UniversityInternshipManagmentSystem.dll'
$json = Join-Path $root 'bin/Newtonsoft.Json.dll'
[void][Reflection.Assembly]::LoadFrom($json)
[void][Reflection.Assembly]::LoadFrom($assembly)
Add-Type -ReferencedAssemblies @($assembly, $json, 'System.Web', 'System.Core', 'System.Net.Http') -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Reflection;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Student.Data;

public static class StudentAuthenticationChecks
{
    private static int count;
    private sealed class FixtureSession : System.Web.HttpSessionStateBase {
        private readonly Dictionary<string,object> values = new Dictionary<string,object>();
        public override object this[string name] { get {object value; return values.TryGetValue(name,out value) ? value : null;} set {values[name]=value;} }
    }
    private sealed class FixtureContext : System.Web.HttpContextBase {
        private readonly FixtureSession session;
        public FixtureContext(FixtureSession session) {this.session=session;}
        public override System.Web.HttpSessionStateBase Session {get{return session;}}
    }
    private static readonly MethodInfo Verify = typeof(StudentFirebaseIdentity).GetMethod("VerifyProjectAsync", BindingFlags.Static | BindingFlags.NonPublic);
    private static string Encode(byte[] bytes) { return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_'); }
    private static string Encode(string value) { return Encode(Encoding.UTF8.GetBytes(value)); }
    private static string Token(JObject claims, RSA rsa, string algorithm = "RS256", string kid = "offline-key")
    {
        var body = Encode(new JObject { { "alg", algorithm }, { "kid", kid } }.ToString()) + "." + Encode(claims.ToString());
        return body + "." + Encode(rsa.SignData(Encoding.ASCII.GetBytes(body), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
    }
    private static StudentAccess CheckToken(string token)
    { return ((Task<StudentAccess>)Verify.Invoke(null, new object[] { token, "offline-identity-project", "student1@example.com" })).GetAwaiter().GetResult(); }
    private static void Reject(string token)
    {
        try { CheckToken(token); }
        catch (UnauthorizedAccessException) { count++; return; }
        throw new Exception("An invalid Firebase token was accepted");
    }
    public static string Run()
    {
        var cache = typeof(StudentFirebaseIdentity).GetField("certificates", BindingFlags.Static | BindingFlags.NonPublic);
        var expiry = typeof(StudentFirebaseIdentity).GetField("certificatesExpire", BindingFlags.Static | BindingFlags.NonPublic);
        var oldCache = cache.GetValue(null);
        var oldExpiry = expiry.GetValue(null);
        using (var rsa = new RSACng(2048))
        {
            var request = new CertificateRequest("CN=Offline Student Authentication Test", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            using (var cert = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-5), DateTimeOffset.UtcNow.AddMinutes(10)))
            {
                // Test keys exist only in this separate PowerShell process. No Google/Firebase requests.
                cache.SetValue(null, new JObject { { "offline-key", "-----BEGIN CERTIFICATE-----\n" + Convert.ToBase64String(cert.RawData) + "\n-----END CERTIFICATE-----" } });
                expiry.SetValue(null, DateTimeOffset.UtcNow.AddMinutes(5));
                try
                {
                    var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                    var claims = new JObject { { "aud", "offline-identity-project" }, { "iss", "https://securetoken.google.com/offline-identity-project" },
                        { "sub", "offline-verified-uid" }, { "email", "student1@example.com" }, { "exp", now + 300 }, { "iat", now - 5 }, { "auth_time", now - 5 },
                        { "firebase", new JObject { { "sign_in_provider", "password" } } } };
                    var token = Token(claims, rsa);
                    if (typeof(StudentFirebaseIdentity).GetMethod("SignInAsync") != null)
                        throw new Exception("A parallel Student sign-in endpoint was retained");
                    count++;
                    var access = CheckToken(token);
                    if (access.FirebaseUid != "offline-verified-uid" || access.StudentId != null || access.EditableFields.Count != 0) throw new Exception("Token verification must not pick a record or grant edit permissions");
                    count++;
                    foreach (var pair in new Dictionary<string, object> { {"aud", "wrong-project"}, {"iss", "https://securetoken.google.com/wrong-project"}, {"sub", ""}, {"email", "other@example.com"}, {"exp", now - 1}, {"iat", now + 100}, {"auth_time", now + 100} })
                    {
                        var changed = (JObject)claims.DeepClone(); changed[pair.Key] = JToken.FromObject(pair.Value); Reject(Token(changed, rsa));
                    }
                    Reject(Token(claims, rsa, "none"));
                    Reject(Token(claims, rsa, "HS256"));
                    Reject(Token(claims, rsa, "RS256", "unknown-key"));
                    var pieces = token.Split('.');
                    Reject(pieces[0] + "." + pieces[1] + "." + Encode(new byte[256]));
                    var tampered = (JObject)claims.DeepClone(); tampered["sub"] = "attacker";
                    Reject(pieces[0] + "." + Encode(tampered.ToString()) + "." + pieces[2]);
                    // Reuse the isolated signing fixture to test the REAL team-session adapter offline.
                    var assembly = typeof(StudentModule).Assembly;
                    var teamType = assembly.GetType("UniversityInternshipManagmentSystem.Student.Data.TeamStudentSession", true);
                    var teamMethod = teamType.GetMethod("GetAccessAsync", BindingFlags.Static | BindingFlags.NonPublic);
                    UniversityInternshipManagmentSystem.Config.AppConfig.DbUrl = "https://team-offline-default-rtdb.europe-west1.firebasedatabase.app/";
                    var teamClaims = (JObject)claims.DeepClone();
                    teamClaims["aud"] = "team-offline";
                    teamClaims["iss"] = "https://securetoken.google.com/team-offline";
                    teamClaims["email"] = "another.student@example.com";
                    var session = new FixtureSession();
                    session["userId"] = "offline-verified-uid";
                    session["dbRecordId"] = "student_team_002";
                    session["dbTable"] = "Students";
                    session["role"] = "student";
                    session["idToken"] = Token(teamClaims, rsa);
                    var context = new FixtureContext(session);
                    Func<StudentAccess> open = () => ((Task<StudentAccess>)teamMethod.Invoke(null, new object[] { context })).GetAwaiter().GetResult();
                    var teamAccess = open();
                    if (teamAccess.StudentId != "student_team_002" || teamAccess.FirebaseUid != "offline-verified-uid"
                        || teamAccess.EditableFields.Count != 0 || !FirebaseStudentRepository.DatabaseUrl.Contains("team-offline"))
                        throw new Exception("Team session mapping/permissions/endpoint failed");
                    count++;
                    foreach (var change in new Dictionary<string, object> { {"userId", "attacker"}, {"role", "company"}, {"dbTable", "Admins"}, {"idToken", token}, {"firstLogin", true} })
                    {
                        var saved = session[change.Key]; session[change.Key] = change.Value;
                        try { open(); throw new Exception("Unsafe team session accepted: " + change.Key); }
                        catch (UnauthorizedAccessException) { count++; }
                        finally { session[change.Key] = saved; }
                    }
                    var owns = typeof(FirebaseStudentRepository).GetMethod("OwnsRecord", BindingFlags.Static | BindingFlags.NonPublic);
                    Func<JObject, bool> ownership = record => (bool)owns.Invoke(null, new object[] { record, teamAccess });
                    if (!ownership(new JObject { {"AuthUid", "offline-verified-uid"} })) throw new Exception("Owner denied"); count++;
                    if (ownership(new JObject { {"AuthUid", "another-user"} })) throw new Exception("Other owner accepted"); count++;
                    if (ownership(new JObject { {"Email", "another.student@example.com"} })) throw new Exception("Email-only ownership accepted"); count++;
                    teamAccess.StudentId = teamAccess.FirebaseUid;
                    if (!ownership(new JObject())) throw new Exception("UID-keyed record denied"); count++;
                    if (ownership(new JObject { {"AuthUid", "other"} })) throw new Exception("Conflicting AuthUid accepted"); count++;

                    Reject("not.a.token");
                    Reject("");
                    if (FirebaseStudentRepository.ProfileWritesEnabled) throw new Exception("Writes enabled unexpectedly");
                    access.StudentId = access.FirebaseUid;
                    var repository = new FirebaseStudentRepository(access);
                    try { repository.UpdateProfileAsync(new Dictionary<string, object> { {"PhoneNumber", "+962700000101"} }).GetAwaiter().GetResult(); throw new Exception("Write was permitted"); }
                    catch (UnauthorizedAccessException) { count++; }
                }
                finally { cache.SetValue(null, oldCache); expiry.SetValue(null, oldExpiry); }
            }
        }
        return "PASS: " + count + " offline cryptographic token and read-only checks; no live Firebase read was attempted.";
    }
}
'@
[StudentAuthenticationChecks]::Run()
