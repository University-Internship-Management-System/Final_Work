# Edit Profile: proposed Rules and activation

**PROPOSAL ONLY — not deployed or tested against the live Rules engine.** Current deployed Rules are reported to permit owned reads and deny all writes. No live write is attempted in this update.

## Exact Firebase Console change for review

The Firebase owner should merge the following `Students` subtree into the existing `rules` object, preserving all other roles and existing policies. This is not a replacement policy for the whole database. The existing owned-record read rule is retained. There must be **no broader `.write` grant at `/`, `/Students`, or `/Students/$studentKey`**: a child restriction cannot revoke an ancestor grant.

```json
{
  "Students": {
    "$studentKey": {
      ".read": "auth !== null && data.child('AuthUid').val() === auth.uid",
      ".write": false,
      "PhoneNumber": {
        ".write": "auth !== null && root.child('Students').child($studentKey).child('AuthUid').val() === auth.uid && root.child('Students').child($studentKey).child('Role').val() === 'Student'",
        ".validate": "newData.isString() && newData.val().length <= 30 && (newData.val() === '' || (newData.val().matches(/^\\+?[0-9 ()-]{7,30}$/) && newData.val().matches(/.*[0-9].*[0-9].*[0-9].*[0-9].*[0-9].*[0-9].*[0-9].*/)))"
      },
      "SkillsList": {
        ".write": "auth !== null && root.child('Students').child($studentKey).child('AuthUid').val() === auth.uid && root.child('Students').child($studentKey).child('Role').val() === 'Student'",
        ".validate": "newData.hasChildren() && newData.numChildren() <= 20",
        "$index": {
          ".validate": "$index.matches(/^(0|[1-9]|1[0-9])$/) && newData.isString() && newData.val().length >= 1 && newData.val().length <= 60 && newData.val().matches(/^[^\\x00-\\x1F\\x7F]+$/)"
        }
      },
      "CvUrl": {
        ".write": "auth !== null && root.child('Students').child($studentKey).child('AuthUid').val() === auth.uid && root.child('Students').child($studentKey).child('Role').val() === 'Student'",
        ".validate": "newData.isString() && newData.val().length <= 2048 && (newData.val() === '' || newData.val().matches(/^https:\\/\\/[A-Za-z0-9.-]+(:[0-9]{1,5})?([\\/?#][^\\s]*)?$/))"
      },
      "PortfolioUrl": {
        ".write": "auth !== null && root.child('Students').child($studentKey).child('AuthUid').val() === auth.uid && root.child('Students').child($studentKey).child('Role').val() === 'Student'",
        ".validate": "newData.isString() && newData.val().length <= 2048 && (newData.val() === '' || newData.val().matches(/^https:\\/\\/[A-Za-z0-9.-]+(:[0-9]{1,5})?([\\/?#][^\\s]*)?$/))"
      },
      "$other": {
        ".write": false
      }
    }
  }
}
```

Only the four leaf paths grant writes, and only for the existing record's owner with Role Student. Name, Email, UniEmail, Major, GPA, Role, AuthUid, CompanyId, AcademicSupervisorId, and all other children receive no write grant. Forged ownership/record creation, whole-record replacement deleting protected fields, another student's PATCH, and overposted protected fields must be denied. Do not add a parent owner-wide `.write`, because that would authorize unrelated fields too.

The URL Rules intentionally accept a conservative DNS/IPv4 HTTPS host format, optional port and path/query/fragment, without embedded user credentials. Internationalized or IPv6 literal links need a separately reviewed policy; the app additionally uses .NET URI validation. Neither the app nor Rules fetch CV/portfolio links. Empty strings clear phone/links; an empty skills array is represented by Firebase as an absent list. The Rules permit deletion only within the four optional personal fields; `.validate` does not run for null/deleted data. No protected field is deletable through this policy.

This grants the owner the four-field policy requested for this isolated Student database. If the official team approves only a subset, remove the other leaf grants and return only that subset in the verified session's EditableFields. Do not store a student-writable policy in the record.

## Required owner checks before publishing

Review the full deployed policy (not available in this checkout) and run Firebase Console simulator or Emulator tests with the real mapped UID. Verify own read and four-field PATCH; another UID, anonymous user, AuthUid change, GPA/Role/assignment change, extra child, child-path injection, record creation/deletion, too-long/invalid phone, HTTP/credential-bearing URL, 21 skills, nonnumeric skill keys, nested skills, and oversized/non-string skills must be denied. Confirm existing immutable fields remain present and unchanged after an allowed PATCH. Rules validation has not been claimed from JSON parsing or fake transport tests.

References: [cascading permissions](https://firebase.google.com/docs/database/security/core-syntax#read_and_write_rules_cascade), [validation and deletion behavior](https://firebase.google.com/docs/database/security/rules-conditions#validating_data), [REST PATCH](https://firebase.google.com/docs/database/rest/save-data#updating_data_with_patch).

## Application activation — currently OFF

The application never changes Firebase Rules. The default is no outgoing writes. After the Firebase owner reviews/tests/publishes the approved Rules, the server operator may explicitly set the **process/server environment variable** `UIMS_STUDENT_PROFILE_WRITES_APPROVED=true` and restart the Student test server. Do not set it from a browser, query string, form field, cookie, or local student data. Do not enable it merely to test against the currently write-denied live database. Leaving it unset keeps Save blocked before HTTP access.

The verified local Student session permits preparing only PhoneNumber, SkillsList, CvUrl, PortfolioUrl after token verification and AuthUid matching. Official team sessions must explicitly provide FirebaseUid and their approved editable-field subset. The write switch alone never authorizes a field or a user. Session identity/token/expiry are re-resolved on Save; the repository snapshots permissions, validates the allowlist, re-reads the bound record's Role/AuthUid, PATCHes only that record's approved fields, and reads back before reporting success.

## UI and test status

Profile has editable approved fields, Save Changes, Cancel, busy/status/error announcements, server validation and encoded messages. Invalid input or permission/service failure keeps entered values. Cancel re-reads the current profile without writing. With the switch off, Save can validate the draft and explain that permission is missing; it sends no update. Academic/account fields remain read-only.

`Tests/Verify-EditProfile.ps1` uses an injected fake HttpMessageHandler in a separate process. It exercises actual repository GET/PATCH/GET sequencing, allowlists, ownership mismatch, Rules-denial responses, and failed persistence confirmation without contacting Firebase. Temporary test-only environment values are restored. These are not live-write verification.

**Live READ:** user reported Ahmad Ali successfully loaded after the previous reorganization; the existing sign-in/read path is preserved. No fresh authenticated read is claimed without a supplied test session/password.

**Live WRITE/read-back:** NOT RUN. Current Rules still deny writes; no Rules were deployed and the live switch was not enabled. The exact next step is the owner-reviewed Rules change above, followed by explicit server activation and a separately verified authorized update/read-back test. No claim of production readiness or live persistence is made from offline tests.
