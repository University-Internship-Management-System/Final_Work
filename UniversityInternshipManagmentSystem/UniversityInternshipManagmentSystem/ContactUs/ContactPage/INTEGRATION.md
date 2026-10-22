# Contact Us integration

## Approved signed-in submission flow

The Contact page uses `Shared/Public.Master` at `/ContactUs/ContactPage/Contact.aspx`.
The existing `/Contact.aspx` and `/Contact` redirects are unchanged.
The owner approved requiring the existing UIMS team login before sending messages.
The form remains visible to guests, but Send is disabled and a team-login link includes
ReturnUrl back to Contact. No separate authentication or administrator login is used.

The page creates `ContactRepository.ForSignedInUser` using the server session. It reads
only the existing userId, role, firstLogin and idToken values; it never changes team
identity/session fields. The existing team AppConfig.DbUrl and ApiKey are reused.
No global configuration, Firebase Rules, shared layout or login implementation is modified.

Before sending, Google accounts:lookup verifies the signed Firebase token over HTTPS.
The returned UID must match Session[userId], the account must not be disabled, and
claims must match the configured project, UID, lifetime and revocation timestamp.
Email and full name entered into the form are contact details, never identity proof.
Only the verified user's ID token is passed to the Realtime Database REST auth parameter.
No message collection reads, administrator credentials, or alternate databases are used.

## Existing message contract and permissions

The original flat path/schema is preserved:
`ContactMessages/{serverGeneratedGuid}` containing FullName (1-100), Email (valid,
up to 254), Subject (1-150), Message (1-4000), CreatedUtc (server UTC ISO8601).
Plain text only. No client-selected record key, role, destination or timestamp.

The database owner must approve authenticated creation with validation of this schema,
and restrict collection reads and message management to approved staff. Do not open
public writes or reads. The code does not change Rules or grant any permissions.
A denied create produces a specific error and preserves the visitor's entries; it is
never treated as a successful submission. Staff retrieval is outside this module;
Coordinator/ContactMessages is currently a team-owned placeholder.

The prior IContactBackendAuthorization contract is retained for compatibility and
isolated tests. The Contact page no longer installs or selects that backend path,
and never falls back to privileged credentials if a user request fails.
Supporting anonymous visitor submission in the future requires a separate approved
backend design; it is not enabled by these changes.

## Submission safeguards

Server validation, encoded output, ViewState MAC/event validation, a session-bound
ViewStateUserKey and CSRF nonce remain enabled. A one-use server GUID is consumed
before network access. Conditional PUT with `if-match: null_etag` prevents overwrite.
A successful response must echo the exact payload before success is shown. Timeouts
and uncertain results are not automatically retried. No local JSON/demo fallback,
message logging, passwords or tokens are stored in code or returned to the browser.
A one-minute session throttle is basic protection; infrastructure rate limits should
be considered by the team before a wider deployment.

## Verification

Run Verify-Contact.ps1 with Windows PowerShell 5.1; it compiles with .NET Framework
4.8 and C# 7.3. Current coverage: 66 fake-transport validation/repository checks and
9 layout/security source checks. No real Firebase calls are made by these tests.
Test-ContactHttp.ps1 takes an optional BaseUrl (default http://localhost:60107)
and exercises anonymous load, validation, HTML handling, denied send and CSRF through
real local Web Forms postbacks. It never signs in or attempts a live Firebase write.

A real authenticated ContactMessages create has not yet been verified. After login,
submit a designated test message once and confirm persistence through an approved
staff/database view. No live success may be claimed based only on builds or fixtures.
