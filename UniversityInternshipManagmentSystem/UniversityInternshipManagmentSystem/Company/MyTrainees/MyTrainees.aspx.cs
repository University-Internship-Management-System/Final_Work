using System;
using System.Globalization;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;

namespace UniversityInternshipManagmentSystem.Company.MyTraineesModule
{
    public partial class MyTraineesPage : Page
    {
        protected override void OnInit(EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            base.OnInit(e);
            SearchInput.Attributes["aria-describedby"] = SearchError.ClientID;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Re-resolve identity and authorizations on every request, including postbacks.
            RegisterAsyncTask(new PageAsyncTask(LoadTraineesAsync));
        }

        private async Task LoadTraineesAsync()
        {
            ClearResults();
            try
            {
                var repository = new MyTraineesRepository();
                var identity = await repository.VerifySupervisorAsync(new HttpContextWrapper(Context));
                CompanyName.Text = HttpUtility.HtmlEncode(identity.CompanyName);
                var result = await repository.GetTraineesAsync(identity);
                BindResults(result);
            }
            catch (UnauthorizedAccessException error) { ShowUnavailable("Company access required", error.Message, 403); }
            catch (TraineesUnavailableException error) { ShowUnavailable("Trainee list unavailable", error.Message, 503); }
            catch (Exception) { ShowUnavailable("Unable to load trainees", "The trainee list is temporarily unavailable. Please try again later.", 500); }
        }

        // Only receives the repository's authorized results, never browser-supplied IDs/data.
        protected internal void BindResults(IList<TraineeRow> result)
        {
            TotalCount.Text = result.Count.ToString(CultureInfo.InvariantCulture);
            SearchInput.Enabled = SearchButton.Enabled = true;
            UnavailableState.Visible = false;
            string query;
            if (!TraineesValidation.TrySearch(SearchInput.Text, out query))
            {
                SearchError.Text = "Use up to 100 plain-text characters for name or major.";
                SearchInput.Attributes["aria-invalid"] = "true";
                EmptyHeading.Text = "Check your search";
                EmptyText.Text = "Correct your search to display results.";
                EmptyState.Visible = true;
                return;
            }
            var matches = result.Where(row => row.Name.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || row.Major.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0).ToList();
            Trainees.DataSource = matches;
            Trainees.DataBind();
            ResultCount.Text = matches.Count.ToString(CultureInfo.InvariantCulture) + " matching trainees";
            EmptyState.Visible = matches.Count == 0;
            EmptyHeading.Text = result.Count == 0 ? "No accepted students or confirmed trainees" : "No matching trainees";
            EmptyText.Text = result.Count == 0 ? "No accepted or confirmed applications with an eligible student relationship were found for your company."
                : "No trainees match this name or major. Try another search.";
        }

        private void ClearResults()
        {
            TotalCount.Text = "Unavailable";
            CompanyName.Text = "Not loaded";
            SearchInput.Enabled = SearchButton.Enabled = false;
            Trainees.DataSource = null;
            Trainees.DataBind();
            UnavailableState.Visible = true;
            EmptyState.Visible = Feedback.Visible = false;
            SearchInput.Attributes.Remove("aria-invalid");
            UnavailableHeading.Text = "Student data is unavailable";
            EmptyHeading.Text = EmptyText.Text = FeedbackText.Text = "";
            SearchError.Text = ResultCount.Text = "";
        }

        private void ShowUnavailable(string heading, string text, int status)
        {
            UnavailableHeading.Text = heading;
            Feedback.Visible = true;
            Feedback.CssClass = status == 500 ? "alert alert-danger" : "alert alert-warning";
            FeedbackText.Text = text; // Literal Mode=Encode; never print Firebase response bodies/exceptions.
            Response.StatusCode = status;
            Response.SuppressFormsAuthenticationRedirect = true;
            Response.TrySkipIisCustomErrors = true;
        }

        protected override void OnError(EventArgs e)
        {
            var validation = Server.GetLastError() is HttpRequestValidationException;
            Server.ClearError();
            Response.Clear();
            Response.StatusCode = validation ? 400 : 500;
            Response.TrySkipIisCustomErrors = true;
            Response.ContentType = "text/plain; charset=utf-8";
            Response.Write(validation ? "The search request is invalid. Reload the page and use plain text."
                : "My Trainees is temporarily unavailable. Please try again later.");
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}
