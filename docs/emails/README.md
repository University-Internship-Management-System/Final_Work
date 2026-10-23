# UIMS emails

There are two kinds of email.

## 1. Sent by Firebase (default Firebase design)
| Email | When |
|---|---|
| Confirm your email | A coordinator creates a Student / Company Supervisor / Academic Supervisor. `Config/EmailVerification.cs` asks Firebase to send it. The new account can **not sign in** until the link is opened (the record gets `RequireEmailVerification: true`; older accounts do not have it and sign in as before). If someone tries to sign in before confirming, Firebase sends a new link. |
| Reset your password | "Forgot Password?" on the login page. |

Firebase's template editor is blocked for our project, so these keep Firebase's default text.
The page where the person types the new password is also Firebase's own.

## 2. Sent by our code through SMTP (UIMS green design)
All of them use one layout, `EmailTemplates/notice.html` (+ `notice.txt` for mail programs that can not show HTML).
`Config/EmailSender.cs` sends, `Config/Notify.cs` has one method for each email. If SMTP is not set up, or a mail fails,
nothing breaks: the page just does not send the email.

| Email | To | When | Where in the code |
|---|---|---|---|
| **Account created** (email, temporary password, steps) | the new person | The coordinator creates a Student / Company / Academic account. Firebase also sends its own "confirm your email" email at the same moment. | `Coordinator/Manage*/...aspx.cs` |
| **Welcome** (what UIMS is, what this person can do) | the person | Right after the person **saves his own password** on the First Login page (once) | `login/FirstLogin.aspx.cs` |
| Account deactivated / active again | the supervisor | The coordinator turns the account off or on | `ManageCompanySupervisors.aspx.cs` |
| Your password was changed | the person | The next sign-in after the password changed (Firebase reset page or the profile page; the profile page sends it at once) | `Notify.AfterSignIn` |
| Academic supervisor assigned | each student + the supervisor | The coordinator assigns students | `AssignAcademicSupervisors.aspx.cs` |
| Application received | the student | The student applies | `Student/ApplicationForm/ApplicationForm.aspx.cs` |
| New application | the company supervisor | The student applies | same |
| Application accepted / not accepted | the student | The company decides (the reason is in the email when rejected) | `Company/ApplicationsReview/ApplicationsReview.aspx.cs` |
| Internship confirmed | the student and the company supervisor | The student confirms the offer | `Student/MyApplications/MyApplications.aspx.cs` |
| Offer declined | the company supervisor | The student declines the offer | same |
| New task | the trainees | A task is created, or a trainee is added to it | `Company/ManageTasks/ManageTasks.aspx.cs` |
| Task updated / closed / opened again | the trainees of the task | The supervisor edits, closes or reopens it | same |
| **Deadline soon** | the trainee | A task is due in the next 24 hours and no work was sent (or changes were asked and not sent). Once per task. | `Config/DeadlineReminders.cs` |
| New work to review | the company supervisor | The trainee sends work (or a new version) | `Student/StudentTasksPage/WeekTasksForm.aspx.cs` |
| Task done (score + feedback) | the trainee | The supervisor saves a score | `Company/ManageTasks/ReviewTask.aspx.cs` |
| Changes needed (feedback) | the trainee | The supervisor asks for changes | same |
| Academic feedback | the student | The academic supervisor writes feedback on a task | `Academic/FinalEvaluation/FinalEvaluation.aspx.cs` |
| Final evaluation sent | the student and the student's academic supervisor | The company sends the final evaluation | `Company/FinalEvaluation/EvaluateTrainee.aspx.cs` |
| Ready for approval | the student and all coordinators/admins | The academic supervisor passes the student | `Academic/FinalEvaluation/FinalEvaluation.aspx.cs` |
| Certificate approved | the student | The coordinator approves the completion | `Coordinator/FinalCompletionReview/FinalCompletionReview.aspx.cs` |

**The first-login flow:** coordinator creates the account -> the person gets the "Account created" email (email + temporary password) and
Firebase's "confirm your email" email -> signs in (after confirming) -> chooses his own password -> gets the "Welcome" email.

**Deadline alerts** use a timer that starts with the website and checks every 30 minutes (the first check 2 minutes after the start).
They read the database with the Firebase admin key (`App_Data/keys/firebase-admin.json`), so they only work when that file exists, and only while the site is running.
Change the 24 hours with `HoursBefore` in `Config/DeadlineReminders.cs`.

How it works: a page calls one method of `Config/Notify.cs` after it saved something. The method does everything else in the
**background** (finds the people, builds the email, sends it), so a page never waits for the database or the mail server, and it
never throws. People are found in the database: `Students`, `CompanySupervisors`, `AcademicSupervisors` (the `Email` field), and
`Admins` + `Coordinators` for the coordinators.

**An email did not arrive?** Open `App_Data/email-log.txt` (next to `Web.config`). Every try is one line: `SENT`, `FAILED` (with the reason, for example a wrong App password) or `SKIPPED` (SMTP not set up, or the person has no email address). The welcome email is only for accounts created after the email confirmation feature, so use a **new** account to test it.

**Sign-in feels slow?** `App_Data/email-log.txt` also gets one `sign-in timing` line per sign-in: how many milliseconds the password check, the profile lookup and the confirmation check took. Send that line to whoever debugs it. (The first sign-in after the site starts is always slower: .NET is warming up.)

To add another email: add a method to `Notify.cs` (copy a short one such as `TaskNews`) and call it from the page (no `await`).

### Port 465, and what happens when the mail server does not answer
The team settings use Gmail on **port 465** (secure from the first byte). Port 587, the usual one, was blocked on one PC: the connection opened but
Gmail's greeting never arrived, so the built-in mail client waited for ever. Now:
- Port **465** uses our own small sender (`SendWithImplicitTls` in `Config/EmailSender.cs`); any other port uses the built-in client.
- **Every send has a time limit** (`SmtpTimeoutSeconds`, 20 by default). When the server does not answer, the send is given up, the log says
  `FAILED ... did not answer in 20 seconds`, and the page carries on. A page or a sign-in can no longer hang because of email.
- The **account created** email is sent while the coordinator waits, so the green message says if it was sent, or **could NOT be sent** (then read the log).

### SMTP settings (already done for the whole team)
The team's email settings (Gmail address and App password) are in `Web.config`, so everybody gets them with `git pull`.
- To send from a different Gmail on **your** PC only: copy `secrets.config.example` to `secrets.config` and fill it in. It overrides `Web.config`.
- The repository must stay **private**: anyone who can read it can send email from this Gmail.

### The other team keys (Firebase admin key, Cloudinary)
They are files in `App_Data/keys/` that are committed on purpose for team testing. See `App_Data/keys/README.md` for how to add and edit them.

## Notes
- The email address used is the `Email` field of the person's record.
- Gmail allows about 500 emails a day. Use a team address as the sender, not a personal one.
