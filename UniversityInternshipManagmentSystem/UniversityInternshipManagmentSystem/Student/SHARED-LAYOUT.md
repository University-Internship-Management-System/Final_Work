# Student direct shared dashboard integration

Both canonical pages now specify exactly:

```aspx
MasterPageFile="~/Shared/Dashboard.Master"
```

- `Student/StudentDashboardPage/Dashboard.aspx`
- `Student/StudentProfilePage/Profile.aspx`

Each page maps its stylesheet content to the existing `HeadContent` and its own Student content to `MainContent`. The common Student stylesheet/script and notices apply only inside the page content. No Student CSS targets body, form, or the shared shell/sidebar/footer/navbar. The redundant content top margin was removed so the shared master controls content spacing.

## Previous mismatch

Both pages previously used `~/Student/Student.Master`. That nested master inherited the shared Dashboard master but also inserted `Shared/Navbar.ascx` into MainContent. This added the public Home/About/Contact/Login navbar inside the role dashboard, producing duplicate branding/navigation and the appearance of a different layout.

The nested Student master and its code-behind/designer were removed from Student and from project registrations. The small page-title behavior moved to the existing StudentPage base class. Page notices and busy state remain in Student content; Firebase/authentication/profile validation code is unchanged.

`Shared/Dashboard.Master` is markup-only in this checkout; no separate code-behind exists. It owns the sidebar, mobile top bar, overlay, main content area, and footer. It does not include the public Navbar, so the corrected Student role pages should not display that extra navbar.

## Team dependencies — Shared files were not edited

Shared/Sidebar.ascx already defines Student Dashboard and My Profile links to the old Student URLs; those URLs continue to redirect to the canonical page folders. It chooses the menu from `Session["role"]` and the displayed name from `Session["name"]`. The isolated Student Firebase test sign-in intentionally does not change these team session keys, so it can show Guest/no menu despite the Student page having a verified Firebase session. The authentication teammate must own any official session/display integration.

The sidebar's current active-link test compares the execution path with its old URLs. Redirected canonical URLs may therefore lack an active highlight. Updating that behavior, or links for other Student modules, is a Shared-owner task. No shared links or global navigation were changed here.

## Verification

Browser checks at 390, 768, and 1440 pixels confirm one shared shell, sidebar, footer, server form, and Student content region; zero extra public navbars or legacy Student shells; working shared mobile menu; no horizontal overflow or script exceptions. Both unauthenticated rendering and explicitly labeled populated UI fixtures were checked in an isolated preview. Original Dashboard and Profile content was preserved verbatim. Profile validation, blocked Save, CSRF rejection, draft preservation, and Cancel were rechecked.

All temporary fixture changes were restored before applying. No local JSON fallback or test authentication hook is added to the real project. These are layout/form checks, not new authenticated Firebase read/write verification. Shared, Firebase, authentication, and Rules source files remain unchanged.

Old Dashboard/Profile/MyProfile redirects and all Student assets remain valid. No branch change, pull, commit, push, merge, or PR.
