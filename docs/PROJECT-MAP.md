# UIMS: Project map (start here)

The web project is `UniversityInternshipManagmentSystem/UniversityInternshipManagmentSystem/`.

## 1. How to start working
1. `git checkout dev` then `git pull origin dev`
2. `git checkout -b feature/<what-you-build>`
3. Build in Visual Studio (it must show 0 errors) and code your page.
4. Before you push: `git pull origin dev`, build again, then `git status`. If you added a file, the `.csproj` must be in the list. Commit it too.
5. `git push -u origin feature/<what-you-build>` and open a Pull Request **into dev**.

Never work directly on `dev` or `main`.

## 2. Where things live
| Folder | What is in it | Who |
|---|---|---|
| `login/` | Login, FirstLogin, Logout | Alaa |
| `Config/` | `AuthHelper` (session + role), `FirebaseDb` (Get/Post/Put/Delete), `AppConfig`, `TaskDb`, `EmailVerification` (Firebase "confirm your email"; new accounts can not sign in until confirmed), `EmailSender` + `Notify` (our SMTP emails: welcome, password changed, task, certificate; secrets in `secrets.config`), `FirebaseAdmin` (not used), see `docs/emails/README.md` | Alaa, Wadea |
| `Models/` | One class per Firebase table | whole team |
| `Shared/` | Layouts (`Dashboard.Master`, `Public.Master`), `Sidebar.ascx`, `Navbar.ascx`, `Footer.ascx`, `uims.css` | Wadea |
| `Student/StudentTasksPage/` | My Tasks: weeks overview + week page | Wadea |
| `Student/Dashboard/` | Student dashboard (login sends students here) | Alaa |
| `Student/StudentDashboardPage/`, `StudentProfilePage/` | Dashboard and Profile (uses another Firebase, see section 5) | Lujain |
| `Student/Opportunities/`, `ApplicationForm/`, `MyApplications/` | Opportunities, apply, my applications | Yaqeen |
| `Student/MyProgress/` | My Progress | abd3348 |
| `Coordinator/ManageStudents/`, `ManageCompanySupervisors/`, `ManageAcademicSupervisors/`, `AssignAcademicSupervisors/` | Account management and supervisor assignment | Marwa |
| `Coordinator/CoordinatorDashbord/`, `CoordinatorMonitor/` | Coordinator dashboard and monitor | Omar |
| `Company/FinalEvaluation/` | Final Evaluation list + one trainee page: the weekly training report (the supervisor signs each week) and the evaluation form (6 skills, 5 levels, then Send). Data: `FinalEvaluations/<student id>` (`Models/FinalEvaluation.cs`). Follows the university form SUJ-KASIT-03-01-02 | Wadea |
| `Company/ManageTasks/` | Tasks (create, edit, open/close) and Review task (score or ask for changes). Every task has `Hours` (its default weight) and an optional `StudentHours` map (studentId -> hours) for the trainees who need a different number; one trainee can have at most 15 hours of open tasks per week. Uses `Config/TaskDb.cs` | Wadea |
| `Company/`, `Academic/` | A placeholder `Dashboard.aspx` plus "Coming soon" pages (see section 4) | nobody yet |
| `Assets/` | Shared css, logo | Alaa |
| `docs/` (outside the web project) | Notes and reports | |
| `FirebaseData/seed.json` | Sample data to import into Firebase | |

## 3. Rules (keep it simple)
- **One login.** Use `AuthHelper` and the guard in `Global.asax.cs`. Do not write your own sign-in or session check. Pages inside `Student/`, `Company/`, `Academic/` and `Coordinator/` are protected automatically.
- **Session expiry.** The Firebase sign-in token lasts 1 hour. The guard in `Global.asax.cs` (rule 0) reads the end time from the token (`AuthHelper.IsTokenExpired`), signs the user out and sends them to `login/Login.aspx?expired=1` with the message "Your session expired. Please sign in again." and the page they came from. You do not need to handle it in your pages.
- **Session keys:** `userId`, `role` (`student`, `company`, `academic`, `coordinator`), `name`, `email`, `idToken`, `firstLogin`.
- **Which id to use for database records:** `userId` is the Firebase *account* id. The record key in the `Students` / `CompanySupervisors` / ... tables is `Session["dbRecordId"]`. Use `Session["dbRecordId"] ?? Session["userId"]` whenever you look up or save something that belongs to a person (tasks, submissions, applications). Otherwise people whose record key is not their account id see no data.
- **Layouts.** Role pages use `~/Shared/Dashboard.Master`. Public pages use `~/Shared/Public.Master`.
- **Where a page goes.** Inside its role folder, in its own subfolder: `Student/MyThing/MyThing.aspx` with its own `.css` and `.js` next to it. Never create new folders at the web root.
- **Sidebar.** Add your page as one line in your role's list in `Shared/Sidebar.ascx`.
- **Data.** Use `Config/FirebaseDb.cs` and the team Firebase in `Web.config`. Do not use another Firebase project.
- **Style.** Use the `--uims-*` variables from `Shared/uims.css`. Do not type hex colors.
- **Always HTML-encode** text that comes from the database before showing it.
- **New file:** Show All Files, then Include In Project, and commit the `.csproj`.

## 4. Pages still to build
Each page below **already exists as a "Coming soon" placeholder** and is linked from the sidebar, so you can open it. To build yours, replace the placeholder file at the **same path** (add a code-behind if you need one, and use the `Shared/ComingSoon.ascx` card only for pages that are not ready).

| Role | Page | Path |
|---|---|---|
| Company | Manage Opportunities | `Company/ManageOpportunities/ManageOpportunities.aspx` |
| Company | Applications | `Company/ApplicationsReview/ApplicationsReview.aspx` |
| Company | My Trainees | `Company/MyTrainees/MyTrainees.aspx` |
| Company | Account | `Company/SupervisorAccount/SupervisorAccount.aspx` |
| Academic | Student Progress | `Academic/StudentProgress/StudentProgress.aspx` |
| Academic | Final Evaluation | `Academic/FinalEvaluation/FinalEvaluation.aspx` |
| Academic | Account | `Academic/SupervisorAccount/SupervisorAccount.aspx` |
| Coordinator | Completion Review | `Coordinator/FinalCompletionReview/FinalCompletionReview.aspx` |
| Coordinator | Contact Messages | `Coordinator/ContactMessages/ContactMessages.aspx` |
| Coordinator | Account | `Coordinator/CoordinatorAccount/CoordinatorAccount.aspx` |
| Student | My Applications | `Student/MyApplications/MyApplications.aspx` |

## 5. Known issues and open decisions
- **Keep the PC clock synced** (Windows Settings, Time & language, Date & time, Sync now). A clock that is a few seconds behind Google's used to make the student pages and My Trainees fail right after login and work after a refresh. They now allow 5 minutes of difference, but a very wrong clock can still cause trouble.
- **Two student dashboards:** `Student/Dashboard/` (Alaa, what login uses) and `Student/StudentDashboardPage/` (Lujain). Decide which one stays.
- **Lujain's Dashboard and Profile read a different Firebase project** (`uims-student-2026`, through `Student/Data/`). They need to use the team database and `AuthHelper`.
- **Demo accounts with passwords written in the code:** `login/Login.aspx.cs` and the quick-login buttons in `login/Login.aspx`. Remove before the demo.
- **`Web.config` has `requestValidationMode="2.0"`.** Typing `<` in a form can show an error page.
- **Home, About and Contact** now use the shared public layout (navbar with Login), but their content is still the ASP.NET template text. `Site.Master` is no longer used by any page.
- **Student `Opportunities`, `ApplicationForm` and `MyApplications`** are standalone pages with no sidebar, so students can't navigate away from them. They should use `~/Shared/Dashboard.Master`.
- **Folder name typo:** `CoordinatorDashbord`. Rename later.
- **Unused files to clean up later:** `Assets/js/*.js` (4 files), `Student/Images/University_of_Jordan_Logo.svg`, the duplicate logos in `login/images/`, the root redirect pages (`Login.aspx`, `FirstLogin.aspx`, `Logout.aspx`, `Student/Dashboard.aspx`, `Profile.aspx`, `MyProfile.aspx`), `Coordinator/Dashboard.aspx` (placeholder, no longer used by login), `Site.Master`, `Site.Mobile.Master`, `ViewSwitcher.ascx`, and the extra solution files.
