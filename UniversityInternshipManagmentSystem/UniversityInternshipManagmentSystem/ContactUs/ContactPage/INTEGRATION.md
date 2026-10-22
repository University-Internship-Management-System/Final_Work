# Contact Us integration

Canonical page: `/ContactUs/ContactPage/Contact.aspx` (FriendlyUrls also serves the extensionless path). The original `/Contact.aspx` and `/Contact` redirect here. Uses Shared/Public.Master directly. No shared files or Student files were changed.

## Current persistence status

OFF. No live Firebase write was attempted. Config/AppConfig.cs points to the team's `universityinternship-f96ef` database; the isolated Student Firebase project is not used. Config/FirebaseDb.cs sends unauthenticated requests and cannot securely accept public contact messages under the requirements. No approved ContactMessages schema, trusted backend token provider, or deployed authorization policy was found in the repository. The page disables Send and explains that the message has not been sent.

## Required team-owned steps

1. Approve the collection/schema below and a backend identity with narrowly scoped access. Do not pass browser credentials or the Student test session to this module. Do not use an unrestricted database secret or administrator credential to bypass Rules.
2. Supply an implementation of `IContactBackendAuthorization` through `Application["ContactModule.BackendAuthorization"]` from trusted server startup. `ContactMessagesApproved` must remain false until the team approves the schema, authorization and spam controls. `GetOAuthAccessTokenAsync()` must return a current approved backend OAuth access token from secure runtime credentials; never hardcode tokens or service-account keys. The provider owns renewal, least-privilege IAM/Rules review, and correct project identity. No provider is installed by this change.
3. Database owner must deny public reads and writes to ContactMessages, allow create-only writes to that collection solely by the approved backend identity, enforce schema/type/length validation, and authorize message retrieval only to approved staff. Review parent grants: RTDB child denials cannot revoke broad parent permissions. OAuth service identities may be authorized through IAM rather than per-user Rules; have the Firebase owner verify that effective access is appropriately restricted. Do not grant project-wide administrator access just to activate this page.
4. Run a controlled live submission with explicit permission. Confirm Firebase response and record persistence through an authorized staff channel. Then enable the provider. No global configuration, auth, Rules, or navigation changes are installed here.
5. Add infrastructure-level rate limits/CAPTCHA before public exposure. The module's one-minute session throttle and one-use submissions are basic protection; new browser sessions bypass session throttling.

Schema proposal (not deployed): `ContactMessages/{serverGeneratedGuid}` with FullName (1–100), Email (valid, up to 254), Subject (1–150), Message (1–4000), CreatedUtc (server UTC ISO8601). Plain text only. No client-selected id, role, destination or status. No list/read endpoint is exposed. Future staff views must encode all stored values. Agree retention/privacy policy before collecting messages.

## Submission behavior

Server validation is authoritative. ViewState MAC, event validation, session-bound ViewStateUserKey and CSRF nonce protect the form. A server-issued, one-use GUID is consumed before network access. A conditional Firebase PUT with `if-match: null_etag` creates one record, prevents overwrites, and never follows redirects carrying credentials. A successful HTTP response must echo the exact allowed payload before success is displayed. A timeout/error is treated as uncertain delivery and is never automatically retried. Entries remain visible on failure. No local storage/JSON/demo fallback, logs of personal messages, or sensitive exception output.

The old root Contact code-behind/designer are retained untouched to avoid unnecessary deletion; the root ASPX is only a fixed internal redirect.

## Verification

Debug and Release solution builds passed with C# 7.3. Run tests with Windows PowerShell 5.1 (.NET Framework), not PowerShell Core. Verify-Contact.ps1 passed 36 offline fake-transport validation/repository checks plus 7 source layout/security checks. Test-ContactHttp.ps1 passed 6 real local HTTPS postback checks (disabled backend, empty/invalid fields, script rejection and output encoding, repeated blocked submissions, CSRF rejection). These are not live Firebase tests. Existing Student regression tests passed 39 + 16 + 47 checks. Browser rendering was checked at 390, 768, 1440 pixels with no horizontal overflow; one shared navbar/footer and disabled Send were confirmed. Current rules and production backend credentials have NOT been inspected through the Firebase Console or exercised.
