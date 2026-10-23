# Contact Messages integration
The existing route now uses `CodeFile="ContactMessages.aspx.cs"` for ASP.NET runtime compilation. Shared master, configuration, login, Rules, and the shared project file were not edited. The pre-existing ASPX Content registration stays unchanged.

For a future packaged Web Application publish, include the new runtime source and stylesheet as **Content**, not Compile (otherwise the CodeFile page would compile the same class twice):
```xml
<Content Include="Coordinator\ContactMessages\ContactMessages.aspx.cs">
  <DependentUpon>ContactMessages.aspx</DependentUpon>
</Content>
<Content Include="Coordinator\ContactMessages\ContactMessages.css" />
```
Do not add duplicates. These entries are proposed only; the current shared project file is preserved.

Access uses the team's ApiKey/DbUrl and the current user's ID token. The repository verifies the token through Firebase accounts:lookup, checks project/lifetime/UID, requires coordinator session + Admins mapping, and verifies Admin or Coordinator role on the owned Admins record. An AuthUid matching the verified UID, or a record key equal to that UID with no conflicting AuthUid, is required. Email matches never authorize access.

The database owner must already permit that staff token to read its Admins record and ContactMessages. Denials are shown; this module changes no permissions and uses no service account or privileged fallback.

Messages reuse FullName, Email, Subject, Message, CreatedUtc. All text is encoded. Reads are capped at 1 MiB and 500 records. Pagination is required before growing beyond that. Search is server-side; messages are never cached in Session/ViewState. This page has no write/delete/reply/handled-status operations. Those need a separately agreed contract and permissions.
