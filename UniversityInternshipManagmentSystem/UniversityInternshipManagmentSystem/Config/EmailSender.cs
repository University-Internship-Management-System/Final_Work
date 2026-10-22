using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Hosting;

namespace UniversityInternshipManagmentSystem.Config
{
    // Sends the emails that our own code sends (the welcome email and the password reset email).
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

        // Sends the welcome email to a new account. Returns "sent", "failed", or "off" (SMTP not set up).
        // It never throws, so a mail problem can not break the creation of the account.
        public static async Task<string> SendWelcome(string name, string role, string email)
        {
            if (!IsConfigured) return "off";
            try
            {
                string loginUrl = HttpContext.Current.Request.Url.GetLeftPart(UriPartial.Authority)
                    + VirtualPathUtility.ToAbsolute("~/login/Login.aspx");
                var values = new Dictionary<string, string>
                {
                    { "NAME", name }, { "ROLE", role }, { "EMAIL", email }, { "LOGIN_URL", loginUrl }
                };
                await Send(email, "Welcome to UIMS", "welcome", values);
                return "sent";
            }
            catch (Exception)
            {
                return "failed";
            }
        }

        // Sends the password reset email with the reset link. Throws when the mail can not be sent.
        public static Task SendPasswordReset(string email, string link)
        {
            var values = new Dictionary<string, string> { { "EMAIL", email }, { "LINK", link } };
            return Send(email, "Reset your UIMS password", "password-reset", values);
        }

        // The sentence the coordinator pages add to the "saved" message.
        public static string MessageFor(string result)
        {
            if (result == "sent") return " A welcome email was sent.";
            if (result == "failed") return " The welcome email could not be sent. Check the SMTP settings.";
            if (result == "off") return " No welcome email was sent because email is not set up (secrets.config).";
            return "";
        }

        // Reads EmailTemplates/<template>.html and .txt, replaces {{KEY}} with the values, and sends both versions.
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

        static string Fill(string template, Dictionary<string, string> values, bool isHtml)
        {
            foreach (var item in values)
                template = template.Replace("{{" + item.Key + "}}", isHtml ? WebUtility.HtmlEncode(item.Value) : item.Value);
            return template;
        }
    }
}
