# MyProgress comparison and integration decision

Review date: 2026-10-22. Branch verified: `feature/student-dashboard-profile`.
Repository: `C:\Users\user\Desktop\UIMS-Team`.

## Decision

No new production integration is justified by MyProgress's identity flow. The Student module already reuses its compatible team session conventions and configured database. MyProgress does not supply a stronger UID-to-student-record ownership proof, so copying its entire implementation would remove an existing protection. No runtime code, Contact file, team-owned file, global configuration or Firebase record was changed during this comparison. The sole new repository file is this report under `Student/MYPROGRESS-COMPARISON.md`.

Existing uncommitted changes, including Shared/Sidebar.ascx and earlier Student/Contact work, were preserved; none are newly attributed to this review. No staging or Git state-changing operation was run.

## Trace of MyProgress

Files inspected: `Student/MyProgress/MyProgress.aspx`, its code-behind/designer/CSS, `Config/TaskDb.cs`, `Config/FirebaseDb.cs`, `Config/AppConfig.cs`, `Config/AuthHelper.cs`, `login/Login.aspx.cs`, global session guards, and Models.Tasks/TaskSubmission/Application/Student/User. Those files were read only.

| Question | Actual behavior |
|---|---|
| Entry guard | Page_Load checks nonempty Session["userId"] inside !IsPostBack; missing session redirects to ~/login/Login.aspx. Global.asax also guards protected role areas and first-login status using team sessions. |
| Student key | LoadProgressAsync uses `(Session["dbRecordId"] ?? Session["userId"]) as string`. It does not derive the record key from a token. |
| Email | MyProgress itself does not inspect email. The login that sets dbRecordId can resolve a record by email after UID lookups fail. |
| Token | FirebaseDb.ResolveToken implicitly reads Session["idToken"] and appends it to REST requests. MyProgress does not independently verify token issuer/signature/UID or ownership of a Students record. Firebase still applies whatever Rules are actually deployed. |
| Reads | FirebaseDb.Get("Tasks") and Get("TaskSubmissions") request entire collections, not student-filtered server queries. |
| Task filtering | Deserializes Dictionary<string, Models.Tasks>, selects StudentIds.Contains(studentKey), copies each Firebase key to TaskId, and keeps WeekNumber 1 through 6. |
| Submission filtering | Selects TaskSubmission.StudentId == studentKey and nonempty TaskId. For each TaskId, chooses highest Version, then latest SubmittedAt. |
| Percentage | Per week, Submitted or Evaluated latest submissions divided by assigned tasks, rounded AwayFromZero. This measures task submission completion, not approved hours. RevisionRequested is not counted as submitted. |
| Hours | ASPX hardcodes 6 weeks, 90 required hours and 15 hours/week. These are not fetched as an authoritative policy or calculated from approved-hour records. |
| Errors | Catches load/deserialization exceptions, displays a generic error and clears the weeks repeater. FirebaseDb.Get returns null on a non-success HTTP response, losing the response's authorization/error distinction for its caller. |

## Why it can display progress when Dashboard/Profile reject a record

MyProgress never requests `Students/{studentKey}` or compares its AuthUid to the signed-in Firebase UID. Tasks/submissions can reference the legacy key held in dbRecordId and therefore be found by its in-memory filters even when that legacy Student record has no matching ownership proof. Showing those counts is not evidence that the current user owns that Student profile.

Its access security depends on the effective deployed Firebase Rules and the correctness of the server session mapping. The source alone does not prove those Rules restrict collection reads appropriately. Filtering an already-downloaded collection does not itself enforce database ownership. This is an observation about the code, not a claim that the deployed database is publicly accessible.

The team's Login calls Firebase Email/Password over HTTPS and saves returned localId/idToken. It searches UID-keyed records first, then scans for Email/UniEmail/CompEmail matches, saving the matched key/table. The Student module additionally verifies the JWT and requires either:

1. Matching `Students/{selectedKey}/AuthUid`; or
2. When AuthUid is absent, `selectedKey == verified Firebase UID`.

An existing contradictory AuthUid always rejects access. Email/name/role alone cannot replace that contract. The previous ownership error means the selected record fails this contract; this review has not read its live contents to distinguish missing AuthUid, contradictory AuthUid or wrong dbRecordId.

## Firebase configuration

MyProgress, FirebaseDb and the current production Student repository all use the team AppConfig.DbUrl:

`https://universityinternship-f96ef-default-rtdb.europe-west1.firebasedatabase.app/`

Expected default-database project: `universityinternship-f96ef`. Student token verification requires matching audience/issuer. The actual live issuer behind the configured API key was not independently established in this review because no valid authorized test session is available. No token or API credential was printed. The old `uims-student-2026` database is not a production data source and no separate sign-in was introduced.

## What is safely reused, and what is not

- Already reused: the team login portal, Session userId/idToken/dbRecordId/dbTable/role conventions, AppConfig's configured HTTPS database, .json REST resource paths, team layouts, async Web Forms loading and team schemas where compatible. These were already in place before this review; no new connection is claimed.
- Student code retains explicit HTTP failure handling, token verification, ownership validation, no JSON fallback, read-only academic fields, CSRF/field validation and closed profile writes.
- Models.Tasks/TaskSubmission can support the same membership/version/submission-percentage semantics once authorized student-specific data can be obtained. No whole-table task/submission reads were added.
- Models.Application supplies StudentId/OpportunityId/Status fields, but MyProgress contains no applications integration or verified ownership resolver. A permitted student-specific query/provider must be approved and tested; it cannot be inferred from the page rendering.
- Feedback/Score in TaskSubmission are not automatically student-visible publications. No release flags/approved feedback contract was found, so supervisor feedback remains unavailable.
- The fixed 90-hour/6-week display is not copied into approved-hour progress. No invented training target, hours, tasks, applications or evaluations were added.

## Exact external dependencies (no changes made)

**Authentication/Firebase owner:** confirm one valid team account and the same Firebase project for Auth and database. Resolve its authoritative Students record. For a legacy key, set AuthUid to the account's real verified UID only after ownership is established, or use the existing UID-keyed record convention with all team references coordinated. Verify effective owner-only Rules. Do not fix this by changing a local session role, email or name.

**Login teammate:** review FetchUserProfileAsync's email fallback. Require a proven UID mapping before setting dbRecordId/dbTable, reject conflicting AuthUid, and clear stale mapping on a failed lookup. This module does not change Login or inject mapping values.

**Tasks/data owner:** approve an owner-scoped retrieval/provider contract for assigned Tasks and TaskSubmissions. StudentIds is a list, so a generic equality query on StudentId is not equivalent for Tasks. No index schema or database node was invented or deployed here. A provider may return only records authorized for the verified student, after the profile ownership gate passes.

**Applications owner:** approve and authorize StudentId-scoped applications queries/provider, including required Rules/indexes. Do not fetch every student's applications then use UI filtering as authorization.

**Evaluation/progress owners:** provide explicit student-release policy for feedback and an authoritative approved-hours/required-hours source. Weekly submission completion cannot stand in for either.

**Profile permission owner:** approve personal-field permissions and matching Rules before writes. Current team access grants no editable fields; no live PATCH was attempted.

## Verification in this review

- Debug and Release solution builds: PASS, .NET Framework 4.8 / C# 7.3.
- Existing Student suites: PASS (39 module + 28 cryptographic/session + 47 profile checks = 114). They use offline signing fixtures and fake HTTP transports, never fake application sessions in the running team app.
- Browser test is limited to reaching the actual team login from Dashboard/Profile without credentials. No authentication attempt or live data access is made when ownership prerequisites are unresolved.
- Live authenticated profile/dashboard read: NOT verified. Profile persistence: NOT attempted/verified. No successful Firebase connection is claimed from a build or redirect.
- Contact Us: unchanged.

Browser verification completed on the existing team application at http://localhost:60107: Dashboard and Profile both redirected to the team Login page with the correct ReturnUrl. No credentials were submitted and no live Firebase operations were attempted. Existing tracked/index changes were compared before and after builds and remained exactly unchanged. Only this new report was added; no runtime implementation was altered.
