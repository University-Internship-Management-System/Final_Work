> Current layout: both pages directly use `~/Shared/Dashboard.Master`. The nested Student.Master and extra public Navbar were removed. See SHARED-LAYOUT.md; this correction supersedes older layout descriptions below.

# Student-only local Firebase sign-in

Firebase project: `uims-student-2026`.
Database: `https://uims-student-2026-default-rtdb.firebaseio.com/`.
Fixed test account: `student1@example.com`; fixed record: `Students/student_001`.

## Running the test

1. Build the existing solution in Debug with Visual Studio/MSBuild.
2. In Windows PowerShell, run `Student/Tests/Start-StudentLocalTest.ps1` from this project. Enter the project's Web API Key when prompted. Alternatively supply `-FirebaseWebApiKey` or enter it in the form. The key is not written to source or global configuration. The optional launcher passes it only to its local server process.
3. Open `https://localhost:44379/Student/StudentProfilePage/Profile`. Use the normal trusted IIS Express localhost development certificate; do not bypass certificate validation. The HTTPS port can be changed within 44300–44399 using `-HttpsPort`.
4. Enter the test password only in the HTTPS form and select **Sign in and read Firebase**. The password is not persisted; neither password nor ID token belongs in chat, scripts, logs, ViewState, browser storage, or source control.
5. A successful request displays the real record and the message **Live Firebase read verified**. Use **Open Student Dashboard** to load the same authorized record on Dashboard. Academic fields stay read-only. The four approved personal fields can be edited as drafts; outgoing writes remain disabled until the owner-approved Rules and server switch are in place. See PROFILE-WRITES.md.
6. Use **Sign out of Student test session** to clear the isolated credential and browser-binding cookie. The shared sidebar's existing logout also clears the ASP.NET session. Restarting IIS Express clears the in-process test session.

The local flow is available only when the request is local, the URL is loopback, HTTPS is used, ASP.NET debugging is enabled, and the team session provider is not registered. HTTP, nonlocal requests, and Release configuration with debugging disabled cannot use it. The launcher does not change Web.config, certificate trust, global Firebase configuration, or authentication startup. If the IIS Express HTTPS certificate/port is not configured on another machine, use Visual Studio's standard local HTTPS setup through the developer who owns the environment.

## Authentication and ownership

The existing team service has no per-user token parameter and no team authentication provider implementation/registration was found. No shared implementation is replaced. The development adapter lives in `Data/StudentDevelopmentSignIn.cs`, uses only its own `Student.Development.*` session state, and does not assign a global principal or write the sidebar's role/name session values. The shared sidebar may therefore continue to display Guest during this isolated test.

Sign-in sends the email/password to the official Firebase Email/Password REST endpoint over HTTPS. The server verifies the returned token's RS256 signature with Google's HTTPS signing certificates, respects certificate cache lifetime, and validates issuer, audience, subject, expiry, issued-at/authentication times, the test email, and password provider. The response localId must equal the verified subject. This is cryptographic signature verification, not simply decoding claims. No service account or database secret is used.

Only then does the server GET `Students/student_001.json?auth=<ID token>`. Firebase Rules enforce ownership. Before storing a session or displaying the result, the repository independently requires the record's `AuthUid` to match the verified UID and its Role to be Student. No database-root listing, cross-role reads, or supervisor lookups are made by the local test flow. Missing/mismatched AuthUid or denied reads fail closed with a visible error.

The token stays in server session memory with its verified UID and expiry. Each Student page load rechecks its signature/project/lifetime and performs the authorized record read. A separate random Secure, HttpOnly, SameSite=Strict cookie binds the local test session to the browser. Sign-in/out use a synchronizer CSRF token and session-bound Web Forms ViewState. No refresh token is stored: sign in again after expiry. This development flow does not implement administrative token-revocation checks or replace production authentication.

## Read-only policy

Outgoing profile writes remain blocked by default before a network request. The verified Student test session now permits editing drafts of PhoneNumber, SkillsList, CvUrl and PortfolioUrl; Save Changes and Cancel are available. PROFILE-WRITES.md documents the owner-reviewed Rules proposal and server-only activation switch. The switch alone never authorizes a user or field. Server validation, AuthUid rechecks, field-only PATCH, and persistence read-back are implemented behind the disabled-by-default write gate. Validation/permission failures preserve drafts; Cancel reloads the saved profile. Academic data remains read-only. No Rules are edited and no write tests are performed.

No page can select the local JSON repository. That legacy class is retained only for explicit offline fixture tests. The Dashboard does not fabricate tasks, applications, evaluations, approved hours, or targets. Activity providers still require their teams' real integration.

## Validation and limits

- Debug and Release builds: passed.
- 39 offline module/validation/activity checks: passed.
- 16 offline cryptographic token/read-only checks: passed, using temporary generated RSA test keys only in a separate PowerShell process. These are not Firebase credentials and are never injected into the running website.
- Local HTTPS Profile form renders; HTTP does not expose a password form.
- Dashboard and Profile checked at 390, 768, and 1440 pixels: shared UI preserved, no overflow or browser script exceptions, no local demo data.
- Actual Email/Password sign-in and authenticated database read require the user to submit the test password in the local form. They must not be claimed successful until that occurs and AuthUid is confirmed.
- No Firebase write was attempted. Existing ownership Rules and all global/team files are unchanged.

Run `Student/Tests/Verify-StudentModule.ps1` and `Student/Tests/Verify-StudentAuthentication.ps1` in Windows PowerShell after building. The browser checker defaults to an unauthenticated page; `STUDENT_EXPECT_AUTHENTICATED=1` checks an already-signed-in browser session, not a password or token passed on the command line.

References: [Firebase Email/Password REST sign-in](https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password), [server-side token verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens).

No commits, pushes, merges, or changes outside Student source are part of this update. The test launch/check scripts are standalone tools under Student/Tests and do not require project-file changes.

## Final page organization and team handoff

Canonical pages are `Student/StudentDashboardPage/Dashboard.aspx` and `Student/StudentProfilePage/Profile.aspx`, each with matching code-behind, designer, and page stylesheet. Namespaces follow those folders under `UniversityInternshipManagmentSystem.Student`. Old Dashboard.aspx, Profile.aspx, and MyProfile.aspx are redirect-only endpoints, so shared navigation remains intact without shared edits.

`Content/Student.css` and `Content/Student.js` contain only common Student content/status behavior. Both canonical pages directly reference `Shared/Dashboard.Master` and its HeadContent/MainContent placeholders. Each HeadContent loads common/page-specific styles; MainContent preserves the original Student content. The shared master renders the sidebar, mobile top bar and footer. No extra public Navbar or nested Student master remains. No private shell or copy of shared CSS is introduced. All Shared files remain byte-identical.

The team currently configures a different global Firebase database through Config/AppConfig.cs. Config/FirebaseDb.cs methods do not accept per-user Firebase ID tokens. Student therefore preserves its isolated uims-student-2026 REST transport. The official integration requires the authentication owner to provide verified user identity/token/expiry and a trusted UID-to-record mapping through IStudentSessionProvider, agree on database project ownership and permitted field policy, and register that provider at startup. This module does not change their settings, login, global principal, or other roles. The local test adapter is disabled whenever the official provider is registered.

Activity teams must register IStudentActivityProvider and return only records belonging to the verified student. StudentOverview.ForStudent defensively handles null lists, filters undated/past deadlines, and excludes evaluations unless both IsPublished and IsStudentVisible are explicitly true. The provider must enforce source-level ownership and confidentiality too. Applications/tasks may contain optional due dates. Approved hours must be nonnegative; the official requirement must be positive. No percentage is rendered without both values; arithmetic caps at 100 without decimal overflow.

Missing activity integrations show unavailable totals and explicit empty states, rather than reporting invented zero activity. A provider failure shows an error. Current Firebase data chiefly contains user/supervisor records; no activity schemas, grading formulas, or training targets are assumed.

Local Student authentication deliberately does not fill shared Session role/name fields. During local testing the sidebar can display Guest. The official authentication owner supplies those display values; shared navigation additions or route ownership remain team dependencies.

Final checks used C# 7.3 for Debug and Release, 39 module/validation/activity checks and 16 cryptographic/read-only checks. Both unauthenticated layouts and populated templates were checked at 390/768/1440 pixels. Populated template checks used an explicitly labeled offline fixture only in the isolated preview; the fixture was removed and the normal source rebuilt before applying. No production test-data fallback or test identity is added. Authenticated Firebase read remains NOT RETESTED without the user submitting the password; no writes were attempted. Old links, module assets, local HTTPS availability, and HTTP sign-in rejection passed.

See FINALIZATION.md for the delivered file map and remaining dependencies. No branch change, pull, commit, push, merge, or PR was performed.
## Edit Profile update

See PROFILE-WRITES.md for the exact non-deployed Rules proposal, activation order, and verification limits. Existing local HTTPS sign-in/token verification remains intact; the user reported Ahmad Ali successfully loaded after reorganization. The agent has not independently reverified a live authenticated read during this edit task. No live writes are attempted while deployed Rules deny writes.

The local verified account receives the task-approved four-field application policy after signature/project verification and AuthUid matching. Official providers must return a verified FirebaseUid and their approved field subset. Draft editing is separate from permission to send a write. The default-disabled server environment switch is UIMS_STUDENT_PROFILE_WRITES_APPROVED; never enable it before the Firebase owner approves and deploys the restricted policy. The repository validates and snapshots inputs/permissions, re-reads the bound record's AuthUid and Role, PATCHes only allowed fields, then performs another GET and compares values before reporting success. Failed persistence confirmation is an error, not a success message.

Tests/Verify-EditProfile.ps1 adds 47 fake-transport validation, authorization, ownership, PATCH, denial, and read-back checks; it never contacts Firebase. Existing 39 module/activity and 16 cryptographic checks remain. Browser form tests in an explicitly labeled isolated fixture confirm editable controls, retained invalid drafts, blocked Save, rejection of posted academic fields/invalid CSRF, and Cancel restoration. Those tests do not establish live persistence. Temporary fixtures are removed before delivery.