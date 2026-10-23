using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
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

        // Builds the email and sends it. It ALWAYS finishes: when the mail server does not answer in SmtpTimeoutSeconds (20 by default)
        // the send is given up and an error is thrown, so a page or a sign-in can never wait for ever.
        //   port 465 = secure from the first byte ("implicit TLS"): our own small sender below (the built-in SmtpClient can not do it)
        //   any other port (587) = the built-in SmtpClient (starts plain, then switches to TLS)
        static async Task Send(string to, string subject, string template, Dictionary<string, string> values)
        {
            string html = Fill(ReadTemplate(template + ".html"), values, true);
            string text = Fill(ReadTemplate(template + ".txt"), values, false);

            string fromAddress = Setting("SmtpFrom") != "" ? Setting("SmtpFrom") : Setting("SmtpUser");
            string fromName = Setting("SmtpFromName") != "" ? Setting("SmtpFromName") : "UIMS";
            int port;
            if (!int.TryParse(Setting("SmtpPort"), out port)) port = 587;
            int seconds;
            if (!int.TryParse(Setting("SmtpTimeoutSeconds"), out seconds) || seconds < 1 || seconds > 120) seconds = 20;

            using (var cancel = new CancellationTokenSource())
            {
                Task sending = port == 465
                    ? SendWithImplicitTls(to, subject, text, html, fromAddress, fromName, port, cancel.Token)
                    : SendWithSmtpClient(to, subject, text, html, fromAddress, fromName, port, cancel.Token);

                if (await Task.WhenAny(sending, Task.Delay(TimeSpan.FromSeconds(seconds))) != sending)
                {
                    cancel.Cancel();                                  // closes the connection
                    Task ignored = sending.ContinueWith(t => { var error = t.Exception; });   // nobody waits for it any more (its error is not needed)
                    throw new TimeoutException("The mail server did not answer in " + seconds + " seconds (port " + port
                        + "). If this keeps happening, your network may block that port: try SmtpPort 465 in Web.config.");
                }
                await sending;
            }
        }

        static async Task SendWithSmtpClient(string to, string subject, string text, string html, string fromAddress, string fromName,
                                             int port, CancellationToken cancel)
        {
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
                    using (cancel.Register(() => client.SendAsyncCancel()))
                        await client.SendMailAsync(message);
                }
            }
        }

        // A small SMTP conversation over a connection that is encrypted from the start (Gmail: smtp.gmail.com port 465).
        static async Task SendWithImplicitTls(string to, string subject, string text, string html, string fromAddress, string fromName,
                                              int port, CancellationToken cancel)
        {
            string host = Setting("SmtpHost");
            using (var tcp = new TcpClient())
            using (cancel.Register(() => tcp.Close()))
            {
                await tcp.ConnectAsync(host, port);
                using (var tls = new SslStream(tcp.GetStream(), false, ValidateServerCertificate))
                {
                    await tls.AuthenticateAsClientAsync(host, null, SslProtocols.Tls12, true);

                    var reader = new StreamReader(tls, Encoding.ASCII);
                    var writer = new StreamWriter(tls, new UTF8Encoding(false)) { NewLine = "\r\n", AutoFlush = true };

                    // read the server's answer (may have several lines) and check its number
                    Func<int, Task> expect = async code =>
                    {
                        string line;
                        do
                        {
                            line = await reader.ReadLineAsync();
                            if (line == null) throw new IOException("The mail server closed the connection.");
                        } while (line.Length >= 4 && line[3] == '-');
                        if (!line.StartsWith(code.ToString())) throw new IOException("The mail server answered: " + line);
                    };

                    await expect(220);
                    await writer.WriteLineAsync("EHLO uims");
                    await expect(250);
                    await writer.WriteLineAsync("AUTH LOGIN");
                    await expect(334);
                    await writer.WriteLineAsync(Convert.ToBase64String(Encoding.UTF8.GetBytes(Setting("SmtpUser"))));
                    await expect(334);
                    await writer.WriteLineAsync(Convert.ToBase64String(Encoding.UTF8.GetBytes(Setting("SmtpPassword"))));
                    await expect(235);
                    await writer.WriteLineAsync("MAIL FROM:<" + fromAddress + ">");
                    await expect(250);
                    await writer.WriteLineAsync("RCPT TO:<" + to + ">");
                    await expect(250);
                    await writer.WriteLineAsync("DATA");
                    await expect(354);
                    await writer.WriteAsync(BuildMessage(to, subject, text, html, fromAddress, fromName));
                    await writer.WriteLineAsync(".");
                    await expect(250);
                    await writer.WriteLineAsync("QUIT");
                }
            }
        }

        // The certificate of the mail server must be valid (it is what proves that we talk to Gmail)
        static bool ValidateServerCertificate(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors)
        {
            return errors == SslPolicyErrors.None;
        }

        // The email as text: headers, then a plain text part and an html part. Names and subject may be Arabic, so they are encoded.
        static string BuildMessage(string to, string subject, string text, string html, string fromAddress, string fromName)
        {
            string boundary = "uims-" + Guid.NewGuid().ToString("N");
            Func<string, string> word = value => "=?utf-8?B?" + Convert.ToBase64String(Encoding.UTF8.GetBytes(value)) + "?=";
            Func<string, string> body = value => Convert.ToBase64String(Encoding.UTF8.GetBytes(value), Base64FormattingOptions.InsertLineBreaks);

            var mail = new StringBuilder();
            mail.Append("From: ").Append(word(fromName)).Append(" <").Append(fromAddress).Append(">\r\n");
            mail.Append("To: ").Append(to).Append("\r\n");
            mail.Append("Subject: ").Append(word(subject)).Append("\r\n");
            mail.Append("Date: ").Append(DateTime.UtcNow.ToString("r", System.Globalization.CultureInfo.InvariantCulture)).Append("\r\n");
            mail.Append("Message-ID: <").Append(Guid.NewGuid().ToString("N")).Append("@uims>\r\n");
            mail.Append("MIME-Version: 1.0\r\n");
            mail.Append("Content-Type: multipart/alternative; boundary=\"").Append(boundary).Append("\"\r\n\r\n");
            mail.Append("--").Append(boundary).Append("\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n");
            mail.Append(body(text)).Append("\r\n");
            mail.Append("--").Append(boundary).Append("\r\nContent-Type: text/html; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n");
            mail.Append(body(html)).Append("\r\n");
            mail.Append("--").Append(boundary).Append("--\r\n");
            return mail.ToString();
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
