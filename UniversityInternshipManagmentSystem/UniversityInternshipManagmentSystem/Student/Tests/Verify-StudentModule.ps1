$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$assemblyPath = Join-Path $projectRoot 'bin/UniversityInternshipManagmentSystem.dll'
$jsonPath = Join-Path $projectRoot 'App_Data/firebase-realtime-dummy-data.json'
[void][System.Reflection.Assembly]::LoadFrom((Join-Path $projectRoot 'bin/Newtonsoft.Json.dll'))
[void][System.Reflection.Assembly]::LoadFrom($assemblyPath)
[xml]$teamConfig = Get-Content (Join-Path $projectRoot 'Web.config')
[UniversityInternshipManagmentSystem.Config.AppConfig]::DbUrl = ($teamConfig.configuration.appSettings.add | Where-Object { $_.key -eq 'DbUrl' }).value
Add-Type -ReferencedAssemblies @($assemblyPath, 'System.Web', 'System.Core') -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Web;
using UniversityInternshipManagmentSystem.Student.Data;

public static class StudentModuleChecks
{
    private static int checks;
    private static void Check(bool condition, string description)
    {
        if (!condition) throw new Exception(description);
        checks++;
    }
    private static void Reject(Action action, string description)
    {
        bool rejected = false;
        try { action(); }
        catch (UnauthorizedAccessException) { rejected = true; }
        catch (ArgumentException) { rejected = true; }
        Check(rejected, description);
    }
    public static string Run(string jsonPath)
    {
        var local = new LocalJsonStudentRepository(jsonPath);
        var profile = local.GetProfileAsync().GetAwaiter().GetResult();
        Check(profile.Student.Name == "Ahmad Ali", "Exact student JSON mapping");
        Check(profile.Student.UniEmail == "student1@university.example.com", "UniEmail mapping");
        Check(profile.Student.GPA == 3.65m, "GPA mapping");
        Check(profile.AcademicSupervisorName == "Omar Haddad", "Supervisor leaf mapping");
        Check(profile.CompanyName == null, "No invented company assignment");
        Reject(() => local.UpdateProfileAsync(new Dictionary<string, object>()).GetAwaiter().GetResult(), "Demo writes denied");
        var allowed = new HashSet<string> { "PhoneNumber", "SkillsList", "CvUrl", "PortfolioUrl" };
        ProfileValidation.ValidatePatch(new Dictionary<string, object> {
            { "PhoneNumber", "+962 700000101" }, { "SkillsList", new List<string> { "C#", "SQL" } },
            { "CvUrl", "https://example.com/cv.pdf" }, { "PortfolioUrl", "" }
        }, allowed);
        Check(true, "Valid personal fields accepted");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "GPA", 4.0m } }, new HashSet<string> { "GPA" }), "Academic field denied even if session policy is wrong");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "Role", "Admin" } }, allowed), "Privilege field denied");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "PhoneNumber", "1234567" } }, new HashSet<string>()), "Unauthorized personal field denied");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "PhoneNumber", "<script>" } }, allowed), "Invalid phone denied");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "PhoneNumber", "-------" } }, allowed), "Phone without digits denied");
        var fieldCopy = ProfileValidation.EditableFields;
        fieldCopy.Add("GPA");
        Check(!ProfileValidation.EditableFields.Contains("GPA"), "Module allowlist cannot be expanded by callers");
        var mutableAccess = new StudentAccess {
            StudentId = "student_001", FirebaseUid = "offline-uid", FirebaseIdToken = "offline-test",
            ExpiresUtc = DateTimeOffset.UtcNow.AddMinutes(5), EditableFields = new HashSet<string>()
        };
        var boundRepository = new FirebaseStudentRepository(mutableAccess);
        mutableAccess.EditableFields.Add("PhoneNumber");
        Reject(() => boundRepository.UpdateProfileAsync(new Dictionary<string, object> { { "PhoneNumber", "1234567" } }).GetAwaiter().GetResult(), "Repository permission snapshot cannot be expanded after construction");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "SkillsList", new List<string> { new string('x', 61) } } }, allowed), "Long skill denied");
        Reject(() => ProfileValidation.ValidatePatch(new Dictionary<string, object> { { "CvUrl", "javascript:alert(1)" } }, allowed), "Unsafe link denied");
        Check(!ProfileValidation.IsSafeUrl("https://user:password@example.com/"), "URL credentials denied");
        Check(!ProfileValidation.IsSafeUrl("http://example.com/"), "HTTP URL denied");
        Check(!ProfileValidation.IsSafeUrl("//example.com/"), "Relative URL denied");
        Reject(() => new FirebaseStudentRepository(new StudentAccess { StudentId = "student_001" }), "Missing token denied before any network request");
        Reject(() => new FirebaseStudentRepository(new StudentAccess { StudentId = "student_001", FirebaseUid = "offline-uid", FirebaseIdToken = "offline-test", ExpiresUtc = DateTimeOffset.UtcNow.AddMinutes(-1) }), "Expired token denied before any network request");
        var previous = StudentModule.SessionProvider;
        Check(FirebaseStudentRepository.DatabaseUrl == UniversityInternshipManagmentSystem.Config.AppConfig.DbUrl.TrimEnd('/' ) + "/", "Student endpoint reuses the team database configuration");
        Check(!FirebaseStudentRepository.ProfileWritesEnabled, "Student writes remain disabled regardless of session permissions");
        try
        {
            StudentModule.SessionProvider = null;
            Reject(() => StudentModule.OpenAsync(new TestContext(true, true, false)).GetAwaiter().GetResult(), "Local debug requests never fall back to JSON");
            Reject(() => StudentModule.OpenAsync(new TestContext(true, true, true)).GetAwaiter().GetResult(), "Authenticated principal without a registered provider cannot select demo data");
            Reject(() => StudentModule.OpenAsync(new TestContext(false, true, false)).GetAwaiter().GetResult(), "Remote demo denied");
            Reject(() => StudentModule.OpenAsync(new TestContext(true, false, false)).GetAwaiter().GetResult(), "Non-debug demo denied");
            var provider = new RejectingProvider();
            StudentModule.SessionProvider = provider;
            Reject(() => StudentModule.OpenAsync(new TestContext(true, true, false)).GetAwaiter().GetResult(), "Anonymous live access denied");
            Check(!provider.Called, "Anonymous request never reaches token provider");
            Reject(() => StudentModule.OpenAsync(new TestContext(true, true, true)).GetAwaiter().GetResult(), "Provider rejection fails closed");
            Check(provider.Called, "Authenticated student reaches trusted provider");
        }
        finally { StudentModule.SessionProvider = previous; }
        var now = DateTimeOffset.UtcNow;
        var overview = StudentOverview.ForStudent(new StudentOverview {
            Applications = null, Tasks = null,
            Deadlines = new List<StudentActivity> {
                new StudentActivity { Title = "later", DueUtc = now.AddDays(2) },
                new StudentActivity { Title = "expired", DueUtc = now.AddDays(-1) },
                new StudentActivity { Title = "unknown date" },
                new StudentActivity { Title = "next", DueUtc = now.AddDays(1) }
            },
            Evaluations = new List<StudentActivity> {
                new StudentActivity { Title = "confidential" },
                new StudentActivity { Title = "published but confidential", IsPublished = true },
                new StudentActivity { Title = "visible but draft", IsStudentVisible = true },
                new StudentActivity { Title = "released", IsPublished = true, IsStudentVisible = true }
            }, ApprovedHours = -1, RequiredHours = 0
        }, now);
        Check(overview.Applications.Count == 0 && overview.Tasks.Count == 0, "Null provider lists are safe empty states");
        Check(overview.Deadlines.Count == 2 && overview.Deadlines[0].Title == "next", "Only dated upcoming deadlines are shown in order");
        Check(overview.Evaluations.Count == 1 && overview.Evaluations[0].Title == "released", "Draft and confidential evaluations are excluded");
        Check(overview.ApprovedHours == null && overview.RequiredHours == null && overview.ProgressPercent == null, "Invalid hours/target cannot produce progress");
        Check(new StudentOverview { ApprovedHours = 40, RequiredHours = 100 }.ProgressPercent == 40, "Official approved-hour progress");
        Check(new StudentOverview { ApprovedHours = 0, RequiredHours = 100 }.ProgressPercent == 0, "Explicit zero approved hours remain valid");
        Check(new StudentOverview { ApprovedHours = decimal.MaxValue, RequiredHours = 1 }.ProgressPercent == 100, "Large hours cap at 100 without overflow");
        Check(new StudentOverview { ApprovedHours = 5 }.ProgressPercent == null, "Missing official requirement never creates progress");
        return "PASS: " + checks + " offline data/validation/identity/activity checks; no Firebase requests made.";
    }
    private sealed class RejectingProvider : IStudentSessionProvider
    {
        public bool Called;
        public Task<StudentAccess> GetVerifiedStudentAsync(HttpContextBase context)
        { Called = true; throw new UnauthorizedAccessException("Rejected test session"); }
    }
    private sealed class TestRequest : HttpRequestBase
    {
        private readonly bool local;
        public TestRequest(bool local) { this.local = local; }
        public override bool IsLocal { get { return local; } }
        public override bool IsSecureConnection { get { return false; } }
    }
    private sealed class TestContext : HttpContextBase
    {
        private readonly bool debug;
        private readonly HttpRequestBase request;
        private readonly IPrincipal user;
        public TestContext(bool local, bool debug, bool authenticated)
        {
            this.debug = debug;
            request = new TestRequest(local);
            user = new GenericPrincipal(new GenericIdentity(authenticated ? "verified-test" : ""), new[] { "Student" });
        }
        public override HttpSessionStateBase Session { get { return null; } }
        public override HttpRequestBase Request { get { return request; } }
        public override bool IsDebuggingEnabled { get { return debug; } }
        public override IPrincipal User { get { return user; } set { throw new NotSupportedException(); } }
    }
}
'@
[StudentModuleChecks]::Run($jsonPath)
