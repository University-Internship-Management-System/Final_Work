# My Trainees integration and registration review

All implementation changes are inside Company/MyTrainees. The shared .csproj, Shared, Config, authentication, Student, Coordinator, ContactUs and Firebase Rules were not modified. No approval object, fake session, runtime compilation workaround or alternate sign-in was added.

## Activation status

The ASPX is now explicitly wired to MyTrainees.aspx.cs / MyTraineesPage with AutoEventWireup=true, Async=true and AsyncTimeout=70. The 70-second page timeout covers four sequential REST calls with existing 15-second request timeouts. Shared/Dashboard.Master, HeadContent and MainContent remain unchanged. Designer fields match the markup, including SearchLabel and SearchPanel.

**The page cannot load the new inherited type until the registrations below are reviewed, applied and the project rebuilt.** Normal Web Application builds do not automatically discover these unregistered C# files. Until that happens, a parser/type-loading error is expected if the guarded route is reached. Registration is a prerequisite, not proof of Firebase authorization. No test DLL was copied into the running application.

## Minimal .csproj proposal — NOT applied

PROJECT-REGISTRATION.patch contains the exact five missing runtime registrations against the inspected project. It adds the following immediately after the existing Content entry for Company\MyTrainees\MyTrainees.aspx, inside its existing ItemGroup. Do not duplicate the existing ASPX registration. Compile and Content items may coexist within this ItemGroup.

```xml
    <Compile Include="Company\MyTrainees\MyTrainees.aspx.cs">
      <DependentUpon>MyTrainees.aspx</DependentUpon>
      <SubType>ASPXCodeBehind</SubType>
    </Compile>
    <Compile Include="Company\MyTrainees\MyTrainees.aspx.designer.cs">
      <DependentUpon>MyTrainees.aspx</DependentUpon>
    </Compile>
    <Compile Include="Company\MyTrainees\MyTraineesRepository.cs" />
    <Content Include="Company\MyTrainees\MyTrainees.css" />
    <Content Include="Company\MyTrainees\MyTrainees.js" />
```

After review, apply only these additions and rebuild the Web Application. Do not apply blindly if another teammate has since registered these files; compare the five Include paths first. Registering the test script, this review document and the patch as None items is optional and is not required to run the page. No package, reference, Web.config or shared startup change is included in the patch.

## Search and states

Each request re-verifies the existing supervisor session before reading or binding trainee data. The total count is independent of search results. Search is case-insensitive by name/major, limited to 100 plain-text characters on the server, and submitted with the panel's DefaultButton so Enter works. Request validation is deferred only on SearchInput; the explicit validator rejects angle brackets/control characters and preserves invalid entered text. Other request validation remains enabled. The repeater and feedback panels do not retain student results in ViewState; fresh authorized data is bound on each request.

Unauthorized identity uses a company-access message and HTTP 403; unavailable permissions/service uses HTTP 503; unexpected errors use a generic HTTP 500. IIS/form-auth error replacement is suppressed for these responses. Empty authorized lists and zero search matches have distinct headings. Search submissions display an accessible busy/loading state and prevent duplicate submissions. The initial server-rendered GET waits for its async work; it does not claim to provide a client-side initial-load spinner. No trainee data is shown on failures.

## Team decisions required before any trainee read

No approval object is created by this module. The backend reads the proposed server-only `Application["Company.MyTrainees.ReadApproval"]` gate; it is absent by default. This is a proposal for deployment review, NOT an existing Firebase schema, authorization rule or team agreement. No HTTP/Session value can enable it. A trusted startup change would be team-owned and was NOT performed.

1. Confirm the supervisor's session record is under CompanySupervisors and belongs to the verified Firebase UID: UID-keyed record or authoritative matching AuthUid. Never link by email alone. The CompanySupervisor model itself has no AuthUid field; the module checks the raw Firebase record without editing that model. Missing/contradictory ownership fails closed.
2. Approve Rules/access and required indexes for BOTH `Students` and `Applications` queries with `orderBy="CompanyId"` and `equalTo={verifiedSupervisorRecordKey}`. The backend never requests either unfiltered collection. Response rows must also match that company; out-of-scope results fail closed. This does not claim the deployed Rules currently support the queries. No Rules/indexes were changed.
3. Approve the proposed conservative confirmation policy: Student.CompanyId matches the supervisor key AND at least one same-company Application has the exact existing ApplicationStatus.Confirmed value for that Student key. Accepted, Pending and Rejected are not confirmation. Without policy approval, no trainee queries run. If the team instead defines confirmation via Opportunity.ConfirmedStudents, that policy must be agreed and adapted before activation; this module does not invent or query that relationship automatically.
4. Name/major are the minimum proposed directory fields. University email is hidden unless separately approved. No personal phone, GPA, CV, portfolio, feedback, hours or profile links are displayed. Do not enable contact disclosure without the data owner's approval.
5. No authenticated live trainee read has been verified. Use a valid authorized Company Supervisor session after activation; do not use Student/admin service-account credentials to bypass Rules.

## Identity/backend behavior

Reads the existing userId, idToken, dbRecordId, dbTable, role and firstLogin session conventions. It never assigns them. Company role is required on every request; coordinator's broader global route access does not automatically grant this page access.

The existing user ID token is submitted server-side to Firebase accounts:lookup using the existing team AppConfig.ApiKey. Only after Firebase accepts it are localId, disabled/revocation state, JWT issuer/audience/UID/lifetime checked against the configured team project and session. Local JWT decoding alone is never trusted. This is account verification, not a new sign-in or token refresh flow. See [Firebase's get-user-data REST reference](https://firebase.google.com/docs/reference/rest/auth#section-get-account-info).

All database requests are HTTPS, token-authenticated reads against existing AppConfig.DbUrl; redirects are disabled and response errors are not disclosed. No passwords, hardcoded tokens/IDs, administrator credentials or local JSON fallback. No writes or trainee-management actions. Applications are used only under the approved policy; Opportunities are not read unnecessarily. Search accepts up to 100 plain-text characters and matches Name/Major only. ViewState is session-bound; output is encoded. Identity/data are reloaded on postbacks rather than stored in ViewState.

## Verification

Run Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Company\MyTrainees\Verify-MyTrainees.ps1
```

The test compiles these unregistered module sources with C# 7.3 against the existing team's built assembly into a unique temporary directory (not the team project/bin). All Auth/database calls in tests use an isolated fake HttpMessageHandler; synthetic test identities never enter the running application or Firebase. Tests cover identity/role/project/lifetime/mapping, closed approval gate, company-filtered queries, confirmation exclusions, contact disclosure, empty/foreign data, read denials and search/encoding.

The existing tests now exercise the actual code-behind BindResults method with offline controls, including case-insensitive name/major search, preserved invalid input, counts, empty/no-match states and populated results. Source checks verify the async/inheritance directive, every designer control/type, master placeholders, encoded bindings and DefaultButton. The test also generates populated-fixture.html in a unique temporary directory using the actual ASPX ItemTemplate, original CSS and existing safe fixture records. That artifact is explicitly labelled offline; it does not execute the shared master or prove ASP.NET runtime parsing, login or Firebase access.

The current Student MyProgress implementation fetches whole Tasks and TaskSubmissions collections and calculates the percentage of assigned tasks with a latest Submitted/Evaluated submission. This is not approved training hours. It is not reused here because a company-scoped authorized read contract has not been established. Existing Tasks.CompanyId / StudentIds and TaskSubmission.StudentId / TaskId provide potential future joins, but query permissions, assignment scope and the authoritative progress policy must be agreed before adding reads. OpportunityTitle, ConfirmedAt and Opportunity.ConfirmedStudents also exist; no new interpretation or training dates/hours are invented.

No authenticated runtime/Firebase success is claimed. ASP.NET parser, team-login postback/loading tests and the real shared layout remain blocked until the shared project registrations are reviewed/applied and a valid authorized Company session is available. The Firebase read gate additionally remains closed pending explicit approved query/confirmation/disclosure policy.
