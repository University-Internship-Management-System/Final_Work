using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Hosting;

namespace UniversityInternshipManagmentSystem.Config
{
    // Sends the emails that our own code sends. The messages themselves are in Notify.cs.
    // (Firebase sends its own "reset your password" and "confirm your email" emails.)
    // The SMTP settings live in secrets.config (not on GitHub). See secrets.config.example.
    public static class EmailSender
    {
        static string Setting(string key)
        {
            return ConfigurationManager.AppSettings[key] ?? "";
        }

        // True when the SMTP settings were filled in.
        public static bool IsConfigured
        {
            get { return Setting("SmtpHost") != "" && Setting("SmtpUser") != "" && Setting("SmtpPassword") != ""; }
        }

        // Sends one email made from EmailTemplates/<template>.html and .txt. Returns true when it was sent.
        // It never throws: a mail problem must not break what the person was doing (saving a task, signing in...).
        public static async Task<bool> TrySend(string to, string subject, string template, Dictionary<string, string> values)
        {
            if (!IsConfigured)
            {
                Log("SKIPPED (SMTP is not set up in secrets.config) | " + subject);
                return false;
            }
            if (string.IsNullOrWhiteSpace(to))
            {
                Log("SKIPPED (this person has no email address) | " + subject);
                return false;
            }
            var timer = System.Diagnostics.Stopwatch.StartNew();
            try
            {
                await Send(to, subject, template, values);
                Log("SENT | " + to + " | " + subject + " | " + timer.ElapsedMilliseconds + " ms");
                return true;
            }
            catch (Exception ex)
            {
                Log("FAILED | " + to + " | " + subject + " | " + (ex.InnerException ?? ex).Message + " | " + timer.ElapsedMilliseconds + " ms");
                return false;
            }
        }

        // One line in App_Data/email-log.txt (never contains a password). Open it to see why an email did not arrive.
        public static void Log(string line)
        {
            try
            {
                File.AppendAllText(HostingEnvironment.MapPath("~/App_Data/email-log.txt"),
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " | " + line + Environment.NewLine);
            }
            catch (Exception)
            {
                // the log must never break anything
            }
        }

        // Sends the password reset email with our design (needs the service account key, see FirebaseAdmin.cs).
        // Throws when the mail can not be sent.
        public static Task SendPasswordReset(string email, string link)
        {
            var values = new Dictionary<string, string> { { "EMAIL", email }, { "LINK", link } };
            return Send(email, "Reset your UIMS password", "password-reset", values);
        }

        static async Task Send(string to, string subject, string template, Dictionary<string, string> values)
        {
            string html = Fill(ReadTemplate(template + ".html"), values, true);
            string text = Fill(ReadTemplate(template + ".txt"), values, false);

            string fromAddress = Setting("SmtpFrom") != "" ? Setting("SmtpFrom") : Setting("SmtpUser");
            string fromName = Setting("SmtpFromName") != "" ? Setting("SmtpFromName") : "UIMS";
            int port;
            if (!int.TryParse(Setting("SmtpPort"), out port)) port = 587;

            using (var message = new MailMessage())
            {
                message.From = new MailAddress(fromAddress, fromName);
                message.To.Add(new MailAddress(to));
                message.Subject = subject;
                // Mail programs that can not show HTML use the plain text version.
                message.Body = text;
                message.BodyEncoding = Encoding.UTF8;   // names can be Arabic
                message.SubjectEncoding = Encoding.UTF8;
                message.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(html, Encoding.UTF8, "text/html"));

                using (var client = new SmtpClient(Setting("SmtpHost"), port))
                {
                    client.Timeout = 20000;   // 20 seconds, not the default 100 seconds
                    client.EnableSsl = !String.Equals(Setting("SmtpSsl"), "false", StringComparison.OrdinalIgnoreCase);
                    client.Credentials = new NetworkCredential(Setting("SmtpUser"), Setting("SmtpPassword"));
                    await client.SendMailAsync(message);
                }
            }
        }

        static string ReadTemplate(string fileName)
        {
            return File.ReadAllText(HostingEnvironment.MapPath("~/EmailTemplates/" + fileName));
        }

        // Replaces {{KEY}} with the values. In the html version the values are HTML-encoded.
        // The part between <!--NOTE--> and <!--/NOTE--> is removed when the value NOTE is empty.
        static string Fill(string template, Dictionary<string, string> values, bool isHtml)
        {
            string note;
            if (!values.TryGetValue("NOTE", out note) || string.IsNullOrWhiteSpace(note))
                template = Regex.Replace(template, "<!--NOTE-->.*?<!--/NOTE-->", "", RegexOptions.Singleline);
            else
                template = template.Replace("<!--NOTE-->", "").Replace("<!--/NOTE-->", "");

            foreach (var item in values)
            {
                string value = item.Value ?? "";
                if (isHtml) value = WebUtility.HtmlEncode(value).Replace("\r\n", "<br>").Replace("\n", "<br>");
                template = template.Replace("{{" + item.Key + "}}", value);
            }
            return template;
        }
    }
}
