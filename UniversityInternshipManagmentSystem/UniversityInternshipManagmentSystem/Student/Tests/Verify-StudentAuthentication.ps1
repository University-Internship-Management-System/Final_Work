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
    private static readonly MethodInfo Verify = typeof(StudentDevelopmentSignIn).GetMethod("VerifyAsync", BindingFlags.Static | BindingFlags.NonPublic);
    private static string Encode(byte[] bytes) { return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_'); }
    private static string Encode(string value) { return Encode(Encoding.UTF8.GetBytes(value)); }
    private static string Token(JObject claims, RSA rsa, string algorithm = "RS256", string kid = "offline-key")
    {
        var body = Encode(new JObject { { "alg", algorithm }, { "kid", kid } }.ToString()) + "." + Encode(claims.ToString());
        return body + "." + Encode(rsa.SignData(Encoding.ASCII.GetBytes(body), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
    }
    private static StudentAccess CheckToken(string token)
    { return ((Task<StudentAccess>)Verify.Invoke(null, new object[] { token })).GetAwaiter().GetResult(); }
    private static void Reject(string token)
    {
        try { CheckToken(token); }
        catch (UnauthorizedAccessException) { count++; return; }
        throw new Exception("An invalid Firebase token was accepted");
    }
    public static string Run()
    {
        var cache = typeof(StudentDevelopmentSignIn).GetField("certificates", BindingFlags.Static | BindingFlags.NonPublic);
        var expiry = typeof(StudentDevelopmentSignIn).GetField("certificatesExpire", BindingFlags.Static | BindingFlags.NonPublic);
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
                    var claims = new JObject { { "aud", "uims-student-2026" }, { "iss", "https://securetoken.google.com/uims-student-2026" },
                        { "sub", "offline-verified-uid" }, { "email", "student1@example.com" }, { "exp", now + 300 }, { "iat", now - 5 }, { "auth_time", now - 5 },
                        { "firebase", new JObject { { "sign_in_provider", "password" } } } };
                    var token = Token(claims, rsa);
                    var access = CheckToken(token);
                    if (access.FirebaseUid != "offline-verified-uid" || access.StudentId != "student_001" || !access.EditableFields.SetEquals(ProfileValidation.EditableFields)) throw new Exception("Verified mapping or approved field policy failed");
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
                    Reject("not.a.token");
                    Reject("");
                    if (FirebaseStudentRepository.ProfileWritesEnabled) throw new Exception("Writes enabled unexpectedly");
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
