using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Hosting;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Config
{
    // The emails our own code sends (through SMTP). One method for each thing that happens in the system.
    //
    // How it works: a page calls a method here after it saved something, for example Notify.TaskDone(...).
    // The method gets what it needs from the request (site address, login token) and then does the rest in the BACKGROUND:
    // it finds the people to tell, builds the email and sends it. So a slow database or mail server never slows a page,
    // and nothing here can throw. When SMTP is not set up nothing is sent. Every try is one line in App_Data/email-log.txt.
    public static class Notify
    {
        // ---- accounts ----

        // The coordinator created an account: the person gets the sign-in details for the first time
        public static void AccountCreated(string name, string role, string email, string temporaryPassword)
        {
            var site = Here();
            Later(async () => await Mail(email, "Your UIMS account", "ACCOUNT CREATED", "Your UIMS account is ready", name,
                "The internship coordinator created a UIMS account for you as a " + RoleLabel(role) + ".\n\n"
                    + "1. Open the email from Firebase and press its link to confirm your email address.\n"
                    + "2. Sign in with the details below.\n"
                    + "3. UIMS asks you to choose your own password.",
                "Your sign-in details", "Email: " + email + "\nTemporary password: " + temporaryPassword
                    + "\n\nKeep this email private. The temporary password stops working once you choose your own.",
                "Open the sign-in page", Link(site, "~/login/Login.aspx")));
        }

        // The coordinator turned an account off or on
        public static void AccountStatusChanged(string name, string email, bool disabled)
        {
            var site = Here();
            Later(async () => await Mail(email, disabled ? "Your UIMS account was deactivated" : "Your UIMS account is active again",
                "ACCOUNT", disabled ? "Your account was deactivated" : "Your account is active again", name,
                disabled ? "The internship coordinator deactivated your UIMS account, so you cannot sign in for now. Please contact the coordinator if you think this is a mistake."
                         : "The internship coordinator activated your UIMS account again. You can sign in as before.",
                null, null, "Open the sign-in page", Link(site, "~/login/Login.aspx")));
        }

        // Called at sign-in, before the session starts. Does two things with ONE read of the person's record:
        // 1. Welcome email, once, for an account that had to confirm its email (it is sent at the first sign-in after the confirmation).
        // 2. "Your password was changed" email, when the password is newer than the last one we told the person about.
        //    This also covers the Firebase reset page, which our website never sees.
        public static async Task AfterSignIn(string table, string recordId, string name, string role, string email, string idToken)
        {
            if (!EmailSender.IsConfigured || string.IsNullOrEmpty(table) || string.IsNullOrEmpty(recordId)) return;
            try
            {
                string json = await FirebaseDb.Get(table, recordId, idToken);
                if (string.IsNullOrEmpty(json) || json.Trim() == "null") return;
                var record = JObject.Parse(json);

                var changes = new JObject();
                bool sendWelcome = IsTrue(record[EmailVerification.RequiredField]) && !IsTrue(record["WelcomeEmailSent"]);
                if (!sendWelcome)
                    EmailSender.Log("sign-in of " + email + ": no welcome email (" + (IsTrue(record["WelcomeEmailSent"]) ? "already sent before"
                        : "this account was not created with the email confirmation, so it has no welcome email") + ")");

                long? passwordTime = await PasswordUpdatedAt(idToken);
                bool sendPasswordChanged = false;
                if (passwordTime.HasValue)
                {
                    long? known = (long?)record["PasswordUpdatedAt"];
                    if (known == null) changes["PasswordUpdatedAt"] = passwordTime.Value;          // first time we see it: just remember it
                    else if (passwordTime.Value > known.Value + 1000) sendPasswordChanged = true;
                }

                if (changes.HasValues) await FirebaseDb.Patch(table, recordId, changes, idToken);

                // The "done" flag is saved only after the email was really sent. If the mail server fails, the next sign-in tries again.
                var site = Here(idToken);
                if (sendWelcome)
                    Later(async () => await Mail(email, "Welcome to UIMS", "EMAIL CONFIRMED", "Welcome to UIMS", name,
                        "Your email is confirmed and your UIMS account is ready. You are signed up as a " + RoleLabel(role) + ".",
                        null, null, "Open UIMS", Link(site, "~/login/Login.aspx"),
                        () => FirebaseDb.Patch(table, recordId, new JObject { { "WelcomeEmailSent", true } }, idToken)));
                if (sendPasswordChanged)
                {
                    string when = DateTimeOffset.FromUnixTimeMilliseconds(passwordTime.Value).ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture) + " (UTC)";
                    long stamp = passwordTime.Value;
                    Later(async () => await Mail(email, "Your UIMS password was changed", "SECURITY", "Your password was changed", name,
                        "The password of your UIMS account was changed on " + when + ". If this was you, nothing else is needed.",
                        "Was this not you?", "Reset your password right away with \"Forgot Password?\" on the sign-in page, and tell the internship coordinator.",
                        "Open UIMS", Link(site, "~/login/Login.aspx"),
                        () => FirebaseDb.Patch(table, recordId, new JObject { { "PasswordUpdatedAt", stamp } }, idToken)));
                }
            }
            catch (Exception ex)
            {
                // Never stop a sign-in because of an email
                EmailSender.Log("sign-in check failed | " + ex.Message);
            }
        }

        // The coordinator gave students an academic supervisor: tell each student, and tell the supervisor
        public static void SupervisorAssigned(string[] studentIds, string academicSupervisorId)
        {
            var site = Here();
            Later(async () =>
            {
                var supervisor = await PersonOf(site, "AcademicSupervisors", academicSupervisorId);
                var names = new List<string>();
                foreach (string id in studentIds)
                {
                    var student = await PersonOf(site, "Students", id);
                    names.Add(student.Name);
                    await Mail(student.Email, "Your academic supervisor", "SUPERVISOR", "You have an academic supervisor", student.Name,
                        supervisor.Name + " is your academic supervisor for the internship.",
                        null, null, "Open UIMS", Link(site, "~/login/Login.aspx"));
                }
                await Mail(supervisor.Email, "New students were assigned to you", "NEW STUDENTS", "Students were assigned to you", supervisor.Name,
                    "The coordinator assigned " + names.Count + " student(s) to you: " + string.Join(", ", names) + ".",
                    null, null, "Open my dashboard", Link(site, "~/Academic/Dashboard.aspx"));
            });
        }

        // ---- opportunities and applications ----

        // A student applied: the student gets a receipt, the company supervisor gets a notice
        public static void ApplicationSubmitted(string studentName, string studentEmail, string opportunity, string company, string companyRecordId)
        {
            var site = Here();
            Later(async () =>
            {
                await Mail(studentEmail, "We received your application", "APPLICATION SENT", "Your application was sent", studentName,
                    "Your application for \"" + opportunity + "\" at " + company + " was sent. You will get an email when the company decides.",
                    null, null, "Open my applications", Link(site, "~/Student/MyApplications/MyApplications.aspx"));
                var supervisor = await PersonOf(site, "CompanySupervisors", companyRecordId);
                await Mail(supervisor.Email, "New application: " + opportunity, "NEW APPLICATION", "You have a new application", supervisor.Name,
                    studentName + " applied for \"" + opportunity + "\". Open the applications page to review it.",
                    null, null, "Review applications", Link(site, "~/Company/ApplicationsReview/ApplicationsReview.aspx"));
            });
        }

        // The company accepted or rejected an application
        public static void ApplicationDecided(string studentId, string opportunity, string company, bool accepted, string reason)
        {
            var site = Here();
            Later(async () =>
            {
                var student = await PersonOf(site, "Students", studentId);
                if (accepted)
                    await Mail(student.Email, "Your application was accepted", "APPLICATION ACCEPTED", "Good news, you were accepted", student.Name,
                        company + " accepted your application for \"" + opportunity + "\". Open My Applications to confirm the offer. "
                            + "When you confirm, you take the seat and your other open applications are cancelled.",
                        null, null, "Open my applications", Link(site, "~/Student/MyApplications/MyApplications.aspx"));
                else
                    await Mail(student.Email, "Update on your application", "APPLICATION UPDATE", "Your application was not accepted", student.Name,
                        company + " did not accept your application for \"" + opportunity + "\". You can apply to other opportunities.",
                        "Reason", reason, "Browse opportunities", Link(site, "~/Student/Opportunities/Opportunities.aspx"));
            });
        }

        // The student confirmed an offer: tell the student, and tell the company supervisor
        public static void OfferConfirmed(string studentName, string studentEmail, string opportunity, string company, string companyRecordId)
        {
            var site = Here();
            Later(async () =>
            {
                await Mail(studentEmail, "Your internship is confirmed", "INTERNSHIP CONFIRMED", "Your internship is confirmed", studentName,
                    "You confirmed your place in \"" + opportunity + "\" at " + company + ". Your tasks will appear on your tasks page.",
                    null, null, "Open my tasks", Link(site, "~/Student/StudentTasksPage/StudentTasksForm.aspx"));
                var supervisor = await PersonOf(site, "CompanySupervisors", companyRecordId);
                await Mail(supervisor.Email, studentName + " confirmed the offer", "NEW TRAINEE", "A student confirmed your offer", supervisor.Name,
                    studentName + " confirmed the offer for \"" + opportunity + "\". They are now your trainee, and you can give them tasks.",
                    null, null, "Open my tasks", Link(site, "~/Company/ManageTasks/ManageTasks.aspx"));
            });
        }

        // The student said no to an offer: tell the company supervisor
        public static void OfferDeclined(string studentName, string opportunity, string companyRecordId)
        {
            var site = Here();
            Later(async () =>
            {
                var supervisor = await PersonOf(site, "CompanySupervisors", companyRecordId);
                await Mail(supervisor.Email, studentName + " declined the offer", "OFFER DECLINED", "A student declined your offer", supervisor.Name,
                    studentName + " declined the offer for \"" + opportunity + "\". The seat is free again.",
                    null, null, "Review applications", Link(site, "~/Company/ApplicationsReview/ApplicationsReview.aspx"));
            });
        }

        // ---- tasks ----

        public static void TaskAssigned(string name, string email, string taskName, int week, DateTime deadline)
        {
            var site = Here();
            Later(async () => await Mail(email, "New task: " + taskName, "NEW TASK", "You have a new task", name,
                "Your company supervisor gave you the task \"" + taskName + "\" (week " + week + "). The deadline is "
                    + deadline.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) + ".",
                null, null, "Open my tasks", Link(site, "~/Student/StudentTasksPage/StudentTasksForm.aspx")));
        }

        // A task of the trainee changed: "was updated", "was closed", "was opened again"
        public static void TaskNews(string name, string email, string taskName, string whatHappened)
        {
            var site = Here();
            Later(async () => await Mail(email, "Task " + whatHappened + ": " + taskName, "TASK UPDATE", "Your task " + whatHappened, name,
                "The task \"" + taskName + "\" " + whatHappened + ". Open your tasks to see the details.",
                null, null, "Open my tasks", Link(site, "~/Student/StudentTasksPage/StudentTasksForm.aspx")));
        }

        // The trainee sent work: tell the company supervisor
        public static void WorkSubmitted(string studentName, string taskName, int version, string companyRecordId)
        {
            var site = Here();
            Later(async () =>
            {
                var supervisor = await PersonOf(site, "CompanySupervisors", companyRecordId);
                await Mail(supervisor.Email, studentName + " sent work: " + taskName, "NEW WORK", version > 1 ? "Work was sent again" : "New work to review", supervisor.Name,
                    studentName + (version > 1 ? " sent a new version (version " + version + ") of" : " sent work for") + " the task \"" + taskName + "\". It is waiting for your review.",
                    null, null, "Review the work", Link(site, "~/Company/ManageTasks/ManageTasks.aspx"));
            });
        }

        public static void TaskDone(string name, string email, string taskName, double score, double maxScore, string feedback)
        {
            var site = Here();
            Later(async () => await Mail(email, "Task done: " + taskName, "TASK DONE", "Your task was evaluated", name,
                "Your work on \"" + taskName + "\" was reviewed. Your score is " + score.ToString(CultureInfo.InvariantCulture)
                    + " out of " + maxScore.ToString(CultureInfo.InvariantCulture) + ".",
                "Feedback from your supervisor", feedback, "Open my tasks", Link(site, "~/Student/StudentTasksPage/StudentTasksForm.aspx")));
        }

        public static void TaskNeedsChanges(string name, string email, string taskName, string feedback)
        {
            var site = Here();
            Later(async () => await Mail(email, "Changes needed: " + taskName, "CHANGES NEEDED", "Please update your work", name,
                "Your supervisor asked you to change your work on \"" + taskName + "\" and send it again.",
                "What to change", feedback, "Open my tasks", Link(site, "~/Student/StudentTasksPage/StudentTasksForm.aspx")));
        }

        // The academic supervisor wrote feedback on a task of the student
        public static void AcademicFeedback(string name, string email, string taskName, string feedback)
        {
            var site = Here();
            Later(async () => await Mail(email, "Feedback from your academic supervisor", "FEEDBACK", "Your academic supervisor left feedback", name,
                "Your academic supervisor wrote feedback on your task \"" + taskName + "\".",
                "Feedback", feedback, "Open my tasks", Link(site, "~/Student/StudentTasksPage/StudentTasksForm.aspx")));
        }

        // ---- final evaluation and certificate ----

        // The company sent the final evaluation: tell the academic supervisor and the student
        public static void CompanyEvaluationSent(string studentId, string studentName, string studentEmail, string company)
        {
            var site = Here();
            Later(async () =>
            {
                await Mail(studentEmail, "Your company finished your evaluation", "EVALUATION", "Your company evaluation was sent", studentName,
                    company + " sent your final evaluation to your academic supervisor.",
                    null, null, "Open my progress", Link(site, "~/Student/MyProgress/MyProgress.aspx"));

                var academic = await AcademicOf(site, studentId);
                await Mail(academic.Email, "Final evaluation to review: " + studentName, "REVIEW", "A final evaluation is waiting for you", academic.Name,
                    company + " sent the final evaluation of " + studentName + ". Please review it and pass the student to the coordinator.",
                    null, null, "Open final evaluations", Link(site, "~/Academic/FinalEvaluation/FinalEvaluation.aspx"));
            });
        }

        // The academic supervisor passed the student: tell the coordinators and the student
        public static void AcademicEvaluationSent(string studentName, string studentEmail)
        {
            var site = Here();
            Later(async () =>
            {
                await Mail(studentEmail, "Your academic supervisor passed you", "EVALUATION", "Your academic evaluation was sent", studentName,
                    "Your academic supervisor passed your internship to the coordinator. The coordinator will approve your certificate.",
                    null, null, "Open my progress", Link(site, "~/Student/MyProgress/MyProgress.aspx"));

                foreach (var coordinator in await Coordinators(site))
                    await Mail(coordinator.Email, "Ready for approval: " + studentName, "APPROVAL", "A student is ready for approval", coordinator.Name,
                        "Both the company and the academic supervisor passed " + studentName + ". You can approve the completion and the certificate.",
                        null, null, "Open completion review", Link(site, "~/Coordinator/FinalCompletionReview/FinalCompletionReview.aspx"));
            });
        }

        public static void CertificateApproved(string name, string email, string coordinatorComment)
        {
            var site = Here();
            Later(async () => await Mail(email, "Your internship certificate is approved", "CERTIFICATE", "Your certificate is ready", name,
                "The coordinator approved the completion of your internship. You can open your certificate on your progress page.",
                "Comment from the coordinator", coordinatorComment, "Open my certificate", Link(site, "~/Student/MyProgress/Certificate.aspx")));
        }

        // ---- the tools used above ----

        // What a background email needs from the request, because there is no request later:
        // the web address of the site, and the login token of the person who did the action (to read other people's records).
        sealed class Site
        {
            public string Root;
            public string Token;
        }

        static Site Here(string token = null)
        {
            var context = HttpContext.Current;
            return new Site
            {
                Root = context.Request.Url.GetLeftPart(UriPartial.Authority) + VirtualPathUtility.ToAbsolute("~/"),
                Token = token ?? (context.Session == null ? null : context.Session["idToken"] as string)
            };
        }

        // "~/Student/X.aspx" -> "https://site/Student/X.aspx" (the email is read outside the website)
        static string Link(Site site, string appRelativePath)
        {
            return site.Root + appRelativePath.Substring(2);
        }

        // Runs the work after the page answered. It never throws, and a failure is written in the log.
        static void Later(Func<Task> work)
        {
            if (!EmailSender.IsConfigured)
            {
                EmailSender.Log("SKIPPED (SMTP is not set up in secrets.config) | a notification");
                return;
            }
            HostingEnvironment.QueueBackgroundWorkItem(async token =>
            {
                try { await work(); }
                catch (Exception ex) { EmailSender.Log("notification failed | " + ex.Message); }
            });
        }

        // Builds one email from EmailTemplates/notice and sends it. onSent runs only when the email really went out.
        static async Task Mail(string to, string subject, string tag, string title, string name, string message,
                               string noteLabel, string note, string buttonText, string buttonUrl, Func<Task> onSent = null)
        {
            var values = new Dictionary<string, string>
            {
                { "TAG", tag }, { "TITLE", title }, { "NAME", string.IsNullOrWhiteSpace(name) ? "there" : name },
                { "MESSAGE", message }, { "NOTE_LABEL", noteLabel ?? "" }, { "NOTE", note ?? "" },
                { "BUTTON_TEXT", buttonText }, { "BUTTON_URL", buttonUrl }
            };
            if (await EmailSender.TrySend(to, subject, "notice", values) && onSent != null) await onSent();
        }

        // Name and email of one record, for example PersonOf(site, "Students", id). Empty when it can not be read.
        static async Task<(string Name, string Email)> PersonOf(Site site, string table, string id)
        {
            try
            {
                if (string.IsNullOrEmpty(id)) return ("", "");
                string json = await FirebaseDb.Get(table, id, site.Token);
                if (string.IsNullOrEmpty(json) || json.Trim() == "null") return ("", "");
                var record = JObject.Parse(json);
                return ((string)record["Name"] ?? "", (string)record["Email"] ?? "");
            }
            catch (Exception)
            {
                return ("", "");
            }
        }

        // The academic supervisor of a student (the student record has AcademicSupervisorId)
        static async Task<(string Name, string Email)> AcademicOf(Site site, string studentId)
        {
            try
            {
                string json = await FirebaseDb.Get("Students", studentId, site.Token);
                if (string.IsNullOrEmpty(json) || json.Trim() == "null") return ("", "");
                return await PersonOf(site, "AcademicSupervisors", (string)JObject.Parse(json)["AcademicSupervisorId"]);
            }
            catch (Exception)
            {
                return ("", "");
            }
        }

        // Everybody who can approve certificates: the people in the Admins and Coordinators tables
        static async Task<List<(string Name, string Email)>> Coordinators(Site site)
        {
            var people = new List<(string Name, string Email)>();
            foreach (string table in new[] { "Admins", "Coordinators" })
            {
                try
                {
                    string json = await FirebaseDb.Get(table, null, site.Token);
                    if (string.IsNullOrEmpty(json) || json.Trim() == "null") continue;
                    foreach (var record in JObject.Parse(json).Properties().Select(p => p.Value).OfType<JObject>())
                    {
                        string email = (string)record["Email"];
                        if (!string.IsNullOrWhiteSpace(email) && !people.Any(p => p.Email == email)) people.Add(((string)record["Name"] ?? "", email));
                    }
                }
                catch (Exception)
                {
                    // the table may not exist or may not be readable: skip it
                }
            }
            return people;
        }

        static string RoleLabel(string role)
        {
            switch ((role ?? "").ToLowerInvariant())
            {
                case "company": case "company supervisor": return "company supervisor";
                case "academic": case "academic supervisor": return "academic supervisor";
                case "coordinator": return "coordinator";
                default: return "student";
            }
        }

        static bool IsTrue(JToken token)
        {
            return token != null && token.Type == JTokenType.Boolean && (bool)token;
        }

        // Firebase keeps the time of the last password change on the login account (milliseconds since 1970).
        static async Task<long?> PasswordUpdatedAt(string idToken)
        {
            var content = new StringContent(JsonConvert.SerializeObject(new { idToken = idToken }), Encoding.UTF8, "application/json");
            using (var response = await FirebaseDb.client.PostAsync(AppConfig.AccountLookupUrl, content))
            {
                if (!response.IsSuccessStatusCode) return null;
                var users = JObject.Parse(await response.Content.ReadAsStringAsync())["users"] as JArray;
                if (users == null || users.Count == 0 || users[0]["passwordUpdatedAt"] == null) return null;
                return (long)(double)users[0]["passwordUpdatedAt"];
            }
        }
    }
}
