# Student / Contact integration review — 2026-10-22

Repository: `C:\Users\user\Desktop\UIMS-Team`  
Branch: `feature/student-dashboard-profile`  
Application folder: `UniversityInternshipManagmentSystem/UniversityInternshipManagmentSystem`

## Outcome

Safe in-scope code fixes are complete. Live identity mapping remains blocked. No new Firebase authentication, read or write request was attempted during this review. Builds and offline tests do not prove production data access. No passwords, ID tokens or refresh tokens were printed. No auth/session values were injected for screenshots.

## Root cause and verified findings

The Sidebar displays Session role/name, which do not prove record ownership. Team login calls Firebase Email/Password, saves localId as `userId`, saves `idToken`, then sets `dbRecordId`/`dbTable` using a UID lookup or an email-based fallback. A legacy record found by email can lack verifiable UID ownership. A previous mapping may also survive if a later lookup fails. The screenshot proves the Student ownership check rejected the selected record; it does not establish which live field is missing/incorrect. Live record contents and deployed Rules were not inspected.

Coordinator student creation currently stores new records under the actual Auth UID. That convention is supported. Existing keyed records require either:

- `Students/{verifiedUid}`, without a conflicting AuthUid; or
- `Students/{legacyKey}/AuthUid` equal to the verified UID.

The Student adapter verifies Google's RS256 signature, issuer/audience, expiry/issued/auth times, password provider, and equality between token UID and server `userId`. Only a trusted session selects the record; no posted ID, email, role or display name can establish ownership. A conflicting AuthUid always denies access. An absent verified UID now fails at repository construction, before a database request.

A separate recent edit in Dashboard registered nonexistent `LoadProgressAsync` instead of existing `LoadDashboardAsync`, causing a build error. That call is repaired, and the identity is checked on postbacks too.

## Project and database

`Config/AppConfig.cs` reads the team's ApiKey/DbUrl from existing Web.config. Configured database:

`https://universityinternship-f96ef-default-rtdb.europe-west1.firebasedatabase.app/`

Expected default-database project: `universityinternship-f96ef`. Production Student requests use the same team DbUrl and require `aud=universityinternship-f96ef` and `iss=https://securetoken.google.com/universityinternship-f96ef`. The live issuer/project behind the API key was NOT independently verified this run; the database owner must confirm they match. No global setting was changed.

The previous `uims-student-2026` project is no longer selected by production Student code. Its test form, password sign-in/sign-out handlers, alternate endpoint branch and fixed test-student selection were retired. The old compile path `Student/Data/StudentDevelopmentSignIn.cs` remains to avoid project churn; it now contains only `StudentFirebaseIdentity` token verification. It collects no credentials and creates no sessions. Legacy launcher/test artifacts are not used for production authentication. Local JSON remains an explicit offline fixture only, never a fallback from live requests.

## Required team-owned actions — NOT performed

1. Auth/Firebase owner: provide a valid team Student account and confirm the Auth project, DbUrl and API key agree. Keep passwords/tokens out of chat and logs.
2. Database owner: inspect the intended Student record against the verified account UID. Authoritatively link legacy records via AuthUid, or use the established UID-key convention. Do not migrate/rename keys without reviewing references in other modules.
3. Auth teammate: review `login/Login.aspx.cs / FetchUserProfileAsync`. Prefer UID ownership; reject contradictory AuthUid/email-only matches. Set dbRecordId/dbTable only from authorized mapping and clear stale mapping when resolution fails. No login code was changed here.
4. Rules owner: verify effective student-owned reads and approved UID mapping. Broad ancestor grants must be reviewed. No Rules were deployed, made public or bypassed.
5. Profile policy owner: authorize the permitted personal fields and matching Rules before enabling saves. Team access currently grants zero editable fields, and the separate server write gate remains closed. Academic/account/assignment fields remain read-only.
6. Shared UI teammate: at 390px the public Navbar brand-text reaches about 514px and creates horizontal overflow. Contact content fits. Fix wrapping/width in Shared after team approval; no page CSS override was added.

## Dashboard data contracts inspected

All original welcome, applications, tasks, deadlines, progress and evaluations content is retained. `StudentModule.ActivityProvider` is unregistered.

| Area | Existing schema | Dependency / current behavior |
|---|---|---|
| Profile | Models.Student/User | Needs ownership mapping and Rules; no live read verified |
| Applications | Models.Application: StudentId, Status, OpportunityId, AppliedAt | MyApplications code-behind is a stub. No approved student query/index/provider registered |
| Tasks | Models.Tasks: StudentIds list, Status, DeadLine, WeekNumber | TaskDb/MyProgress fetch whole collections then filter; no approved owner-scoped dashboard provider/index contract |
| Deadlines | Tasks.DeadLine; Opportunity.ApplicationDeadline | Must use authorized student-associated records; no provider registered |
| Evaluations | TaskSubmission Score/Feedback; other evaluation placeholders | No agreed published/student-visible release policy; no confidential feedback exposed |
| Progress | MyProgress computes weekly submitted-task percentages | No authoritative approved-hours/required-hours contract. Weekly completion is not approved training hours; no hours target assumed |
| Assignments | CompanyId/AcademicSupervisorId | Relationship-name reads need an approved provider; no supervisor collection scans |

Sections honestly remain unavailable/not connected until approved data contracts exist. No totals, applications, tasks, published evaluations, hours or targets were invented. A failed profile load does not expose partially authorized personal data. The mode badge now distinguishes an existing team session with unavailable data from an absent login.

## Contact Us

Uses Shared/Public.Master, team variables and one shared Navbar/Footer. Root Contact still redirects to the single ContactUs implementation. No global route/navigation changes were made.

Persistence is OFF: `ContactModule.BackendAuthorization` is not registered, and no approved ContactMessages schema/authorization deployment was found. The existing backend interface must be supplied by the responsible teammate. No anonymous/browser writes, Student-project connection or false success result was introduced.

The team's `requestValidationMode="2.0"` caused script/HTML inputs to throw before Contact's field validation. Contact now uses page-scoped manual validation (`ValidateRequest="false"`), strictly rejecting HTML, control characters, invalid email and excessive lengths before any persistence. Output controls encode values; stored HTML is not allowed. Web.config and global validation are unchanged. CSRF, session throttling, one-use IDs, create-only conditional writes and response confirmation remain intact.

## Verification results

- Debug and Release solution builds: PASS (.NET Framework 4.8, C# 7.3).
- Student: 39 module + 28 cryptographic/session + 47 profile fake-transport checks. No live Firebase requests.
- Contact: 36 fake-transport/validation + 7 source checks; 6 real local Web Forms HTTP postback checks on the existing team app at port 60107. The legacy test output says HTTPS, but this run used local HTTP with synthetic non-sensitive input. Empty/invalid fields, script rejection/encoding, repeated blocked submissions and CSRF rejection passed.
- Browser: Dashboard/Profile redirect unauthenticated users to team Login with ReturnUrl. No isolated Student form remains. Real private Student data and its responsive layout could not be tested without a valid authorized account.
- Contact browser: old route works, one Navbar/Footer, disabled Send. Actual widths 390/768/1440 checked: content fits; 390 has Shared-brand overflow, 768/1440 have no horizontal overflow.
- Student pages directly use `~/Shared/Dashboard.Master`; Contact directly uses `~/Shared/Public.Master`.
- Live Student read NOT verified; live Profile write NOT attempted/verified; live Contact persistence NOT attempted/verified.
- Existing dirty changes outside Student/Contact and all staged entries preserved. No staging, branch switch, pull, merge, reset, rebase, commit, push or PR.

## Exact files changed in this review

Relative to the application folder above:

1. Student/StudentDashboardPage/Dashboard.aspx.cs — correct async loader on every request.
2. Student/StudentPage.cs — team login only; accurate unavailable-data badge.
3. Student/StudentProfilePage/Profile.aspx — retire isolated test controls, retain profile design.
4. Student/StudentProfilePage/Profile.aspx.cs — retire test auth handlers; retain secure Save/Cancel.
5. Student/StudentProfilePage/Profile.aspx.designer.cs — remove retired controls only.
6. Student/Data/StudentRepository.cs — team database only; mandatory verified UID; no dev fallback/endpoint or extra relationship reads.
7. Student/Data/StudentModels.cs — remove development-session flag.
8. Student/Data/StudentDevelopmentSignIn.cs — verification-only implementation in existing compile path.
9. Student/Tests/Verify-StudentModule.ps1 — UID required in fixture.
10. Student/Tests/Verify-StudentAuthentication.ps1 — generic verifier fixture; no parallel sign-in API check.
11. Student/Tests/Verify-EditProfile.ps1 — constructor rejection and reflection exception handling.
12. ContactUs/ContactPage/Contact.aspx — explicit manual validation compatibility and comment.
13. Student/TEAM-INTEGRATION-REVIEW.md — this report.

No .csproj edits required. Shared/Sidebar.ascx already had an approved local change before this review and was preserved exactly. Config, Web.config, Shared components, all other team modules and Contact backend were not changed by this review.
