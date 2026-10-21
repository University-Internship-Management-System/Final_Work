# Student module migration — 2026-10-21

Source: `C:\Users\user\Desktop\UIMS` (read only).
Destination: `C:\Users\user\Desktop\UIMS-Team`.

The old Student module was already present in the destination at the start of this update. All Student implementation files matched the old project after destination namespace/assembly substitutions; images and stylesheet initially matched byte for byte. This update finishes the shared UI integration.

## Organization and changes

Personal module work is organized under `UniversityInternshipManagmentSystem/UniversityInternshipManagmentSystem/Student/`:

- `Dashboard.aspx` and its code-behind/designer: dashboard and summaries.
- `Profile.aspx` and its code-behind/designer: profile and authorized editing, renamed from MyProfile to match the shared sidebar.
- `MyProfile.aspx`: compatibility redirect to Profile.
- `Student.Master` and its code-behind/designer: a thin nested master using `Shared/Dashboard.Master`; navbar comes from `Shared/Navbar.ascx`, sidebar/footer are inherited from the shared dashboard master.
- `StudentPage.cs`: existing common student behavior.
- `Data/`: existing repository, validation, and Student module contracts.
- `Content/Dashboard.css`: content-only styles using shared design variables; custom shell styles removed.
- `Images/`: original campus image and emblem preserved.
- `Tests/`: offline checks and browser verification updated for the shared layout.
- `INTEGRATION.md`: ownership, integration contracts, and verification instructions.

Development JSON remains in protected `App_Data/`. Project registrations are updated for Profile and its compatibility page. Old root templates, build output, IDE state, and package caches are not migrated as team source.

## Team work preserved

Shared files, root masters, startup/configuration, team Models, authentication, Firebase configuration, other role folders, package manifests, and solution files are unchanged. The only project-wide source edit is the `.csproj` registration adjustment for Student files. No commits, pushes, merges, database writes, or dependency upgrades are performed.

## Validation

An isolated copy was used to build and run the changes before applying them:

- Debug and Release builds succeeded without warnings/errors.
- All 27 existing offline repository/validation/identity checks passed; no Firebase requests.
- Dashboard and Profile at 390, 768, and 1440 pixels rendered with no horizontal overflow, exactly one shared navbar/sidebar/footer, and no legacy shell.
- Shared mobile menu opens and closes.
- MyProfile compatibility URL redirects to Profile.
- Source comparison limits changes to Student, its project registrations, and this report.

## Remaining team integrations

Authentication must register `IStudentSessionProvider` and populate `Session["role"]` and `Session["name"]` for the shared sidebar. Until then, the local Student demo stays read-only and the unmodified sidebar displays Guest without role links. No artificial student authentication is introduced.

Activity teams must provide `IStudentActivityProvider` for real applications, tasks, deadlines, published evaluations, and official training-hour totals/requirements. Existing empty states remain. Other sidebar routes and Login belong to their team owners. See `Student/INTEGRATION.md` for contracts.
