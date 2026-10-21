> Current layout: both pages directly use `~/Shared/Dashboard.Master`. The nested Student.Master and extra public Navbar were removed. See SHARED-LAYOUT.md; this correction supersedes older layout descriptions below.

# Student Dashboard and Profile finalization

Branch: `feature/student-dashboard-profile` (unchanged).
Stack: existing ASP.NET Web Forms application, .NET Framework 4.8, C# 7.3, Bootstrap 5.2.3.

## Delivered organization

```
Student/
  StudentDashboardPage/
    Dashboard.aspx
    Dashboard.aspx.cs
    Dashboard.aspx.designer.cs
    Dashboard.css
  StudentProfilePage/
    Profile.aspx
    Profile.aspx.cs
    Profile.aspx.designer.cs
    Profile.css
  Content/
    Student.css
    Student.js
  Data/
    StudentRepository.cs
    StudentDevelopmentSignIn.cs
    StudentModels.cs
    ProfileValidation.cs
  Images/
  Tests/
    Start-StudentLocalTest.ps1
    Verify-StudentModule.ps1
    Verify-StudentAuthentication.ps1
    Verify-StudentPages.cjs
  StudentPage.cs
  Dashboard.aspx, Profile.aspx, MyProfile.aspx (redirects only)
  INTEGRATION.md
  FINALIZATION.md
```

The two implementations were moved, not copied. Their namespaces, directives, links, assets, master placeholders, and project registrations follow the new folders. Authentication was extracted from the repository into its own Student file without changing the verification/session implementation. Shared Student status JavaScript was moved out of markup. No separate ASP.NET project or page-specific JavaScript was needed.

## Dashboard

Welcome/profile access, applications and statuses, assigned tasks and optional due dates, upcoming deadlines, released evaluations/feedback, approved hours, official requirements, and internship status are supported by the existing provider contract. Missing integrations now show unavailable totals; they are not interpreted as confirmed zero activity. Empty states remain.

Confidential/draft evaluations are excluded unless explicitly published and student-visible. Only dated upcoming deadlines are shown. Null provider lists are safe. Negative hours or invalid requirements are unavailable, and percentages require valid values with overflow-safe capping at 100. No activity records, grades, or targets were fabricated.

## Profile

The existing encoded academic/account details, phone, skills, safe HTTPS CV/portfolio links, and assignment information are preserved. Academic/account data remains read-only. CSRF/session protections, server validation, clear errors, and the local HTTPS sign-in remain. All writes stay disabled before network access; approved-field editing remains prepared behind the permission/policy gate.

## Shared layout and team safety

Both Student pages directly use Shared/Dashboard.Master with HeadContent/MainContent. Its sidebar, mobile top bar and footer render once. The nested Student master and its extra public Navbar were removed. Styles use Inter, shared design variables, and Bootstrap. Shared files, global navigation, Web.config, configuration, other roles, shared Models, and authentication startup are not changed. Only Student files and targeted Student `.csproj` registrations change.

## Verification

- Existing solution Debug and Release builds with `/p:LangVersion=7.3`.
- 39 offline module/validation/identity/activity checks.
- 16 offline cryptographic token/read-only checks.
- Both pages at 390, 768, and 1440 pixels: unauthenticated state and clearly labeled offline populated-template fixture, no overflow/script exceptions, one shared sidebar/footer/shell, with no extra public Navbar, working shared mobile menu.
- Old Dashboard/Profile/MyProfile routes redirect to their canonical page folders. Student styles/script/campus asset return HTTP 200.
- Local HTTPS test form remains available; HTTP exposes no password form.
- The isolated populated-layout fixture is removed before delivery; normal code is rebuilt. It is not a live Firebase test or production fallback.
- **Live authenticated Firebase read: NOT RETESTED in this finalization; no test password/session was supplied to the agent.**
- **Firebase writes: DISABLED; no write or persistence test performed.**

## Integration dependencies and remaining work

The local read-only test targets `uims-student-2026` and requires a valid test password plus an AuthUid match. The authentication owner must supply the official verified session/UID mapping and approved field policy before production integration. Global team Firebase settings currently target a different project; they remain unchanged. Activity owners must supply authorized records and explicit evaluation publication/visibility flags. The database owner must approve and enforce ownership/field Rules before any writes can be enabled.

Within this assignment, page organization, safe rendering, validation, read-only protections, and provider-ready dashboard sections are completed. A real authenticated regression read still requires the test user to sign in; activity-backed production data and profile saving remain gated by the team contracts above. No claim of live read or write success is made from a build or offline fixture.

No pull, commit, push, merge, branch change, or PR.

## Edit Profile follow-up

The later Edit Profile task adds Save Changes/Cancel and drafting of the four approved personal fields. Current Firebase writes remain disabled by default and no deployed Rules were changed. The repository is prepared for verified ownership-checked PATCH and fresh read-back after owner-approved activation. PROFILE-WRITES.md supersedes the earlier read-only UI description and contains the exact Rules proposal/activation requirements. Tests/Verify-EditProfile.ps1 adds 47 offline checks; live writes are not claimed from them.