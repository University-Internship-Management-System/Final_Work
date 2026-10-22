using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;

namespace UniversityInternshipManagmentSystem.ContactModule
{
    public partial class ContactPage : Page
    {
        private const string Prefix = "ContactModule.";
        private ContactRepository repository;
        protected override void OnInit(EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
            repository = new ContactRepository(Application["ContactModule.BackendAuthorization"] as IContactBackendAuthorization);
            base.OnInit(e);
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            if (!IsPostBack)
            {
                if (Session[Prefix + "Csrf"] == null) Session[Prefix + "Csrf"] = Guid.NewGuid().ToString("N");
                Csrf.Value = (string)Session[Prefix + "Csrf"];
                Submission.Value = Guid.NewGuid().ToString("N");
                Session[Prefix + "PendingId"] = Submission.Value;
                Session[Prefix + "PendingIssued"] = DateTime.UtcNow;
            }
            Availability.Visible = !repository.IsAvailable;
            Send.Enabled = repository.IsAvailable;
        }
        protected void Send_Click(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(SendAsync));
        }
        private async System.Threading.Tasks.Task SendAsync()
        {
            NameError.Text = EmailError.Text = SubjectError.Text = MessageError.Text = "";
            Guid id;
            var issued = Session[Prefix + "PendingIssued"] as DateTime?;
            if (string.IsNullOrEmpty(Csrf.Value) || Csrf.Value != (string)Session[Prefix + "Csrf"]
                || Submission.Value != (string)Session[Prefix + "PendingId"]
                || !Guid.TryParseExact(Submission.Value, "N", out id) || !issued.HasValue
                || issued.Value < DateTime.UtcNow.AddHours(-1))
            { Show("This form has expired or was already submitted. Reload the page before trying again.", false); return; }
            var message = new ContactMessage { FullName = FullName.Text.Trim(), Email = Email.Text.Trim(), Subject = Subject.Text.Trim(), Message = Message.Text.Trim() };
            var errors = ContactValidation.Validate(message);
            SetError(errors, "FullName", NameError, FullName);
            SetError(errors, "Email", EmailError, Email);
            SetError(errors, "Subject", SubjectError, Subject);
            SetError(errors, "Message", MessageError, Message);
            if (errors.Count != 0) { Show("Please correct the highlighted fields. Your message has not been sent.", false); return; }
            if (!repository.IsAvailable) { Show("Secure message sending is not configured. Your message has not been sent.", false); return; }
            var last = Session[Prefix + "LastAttempt"] as DateTime?;
            if (last.HasValue && DateTime.UtcNow - last.Value < TimeSpan.FromSeconds(60))
            { Show("Please wait one minute before sending another message.", false); return; }
            Session[Prefix + "LastAttempt"] = DateTime.UtcNow;
            // Consume BEFORE network access: retries after an uncertain network result cannot duplicate a message.
            Session.Remove(Prefix + "PendingId");
            Session.Remove(Prefix + "PendingIssued");
            try
            {
                await repository.SaveAsync(id, message);
                FullName.Text = Email.Text = Subject.Text = Message.Text = "";
                Send.Enabled = false;
                Show("Your message was saved successfully. Thank you for contacting UIMS.", true);
            }
            catch (Exception)
            {
                // No personal data, credentials or exception details are returned to the visitor.
                Send.Enabled = false;
                Show("We could not confirm delivery. Your entries are preserved. Please wait and reload before retrying; avoid resending if delivery is uncertain.", false);
            }
        }
        private void Show(string text, bool success)
        {
            Feedback.Visible = true;
            Feedback.CssClass = success ? "alert alert-success" : "alert alert-danger";
            FeedbackText.Text = text;
        }
        private static void SetError(IDictionary<string, string> errors, string key, System.Web.UI.WebControls.Label label, System.Web.UI.WebControls.TextBox input)
        {
            string error;
            var invalid = errors.TryGetValue(key, out error);
            label.Text = invalid ? HttpUtility.HtmlEncode(error) : "";
            input.Attributes["aria-invalid"] = invalid ? "true" : "false";
            input.Attributes["aria-describedby"] = label.ClientID;
        }
    }
}
