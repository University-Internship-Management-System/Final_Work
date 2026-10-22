using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using Newtonsoft.Json;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem
{
    public partial class PublicHome : Page
    {
        protected string PublicDataJson { get; private set; } = "{}";
        protected bool IsSignedIn { get { return AuthHelper.IsAuthenticated; } }
        protected string SignedInName { get { return AuthHelper.UserName ?? "Student"; } }
        protected string DashboardHref
        {
            get
            {
                return ResolveUrl(IsSignedIn
                    ? AuthHelper.GetDashboardUrl(AuthHelper.UserRole)
                    : "~/login/Login.aspx");
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            RegisterAsyncTask(new PageAsyncTask(LoadOpportunitiesAsync));
        }

        private async Task LoadOpportunitiesAsync()
        {
            var opportunities = new List<object>();
            string message;

            try
            {
                string json;
                // Use the existing database configuration and signed-in token.
                // No credentials or private Firebase records are sent to JavaScript.
                using (var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10)))
                using (var response = await FirebaseDb.client.GetAsync(
                    FirebaseDb.BuildUrl("Opportunities", null, AuthHelper.IdToken), timeout.Token))
                {
                    response.EnsureSuccessStatusCode();
                    json = await response.Content.ReadAsStringAsync();
                }

                if (string.IsNullOrWhiteSpace(json))
                    throw new InvalidOperationException("Empty Firebase response.");

                var records = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(json)
                    ?? new Dictionary<string, Opportunity>();

                foreach (var record in records
                    .Where(item => item.Value != null
                        && string.Equals(item.Value.Status, OpportunityStatus.Open, StringComparison.OrdinalIgnoreCase)
                        && !item.Value.IsDeadlinePassed && item.Value.SeatsLeft > 0)
                    .OrderByDescending(item => item.Value.CreatedAt)
                    .ThenBy(item => item.Key, StringComparer.Ordinal)
                    .Take(12))
                {
                    Opportunity item = record.Value;
                    item.Id = record.Key;
                    // Only public listing fields are projected. In particular,
                    // ConfirmedStudents and their identifiers are never serialized.
                    opportunities.Add(new
                    {
                        id = item.Id,
                        title = string.IsNullOrWhiteSpace(item.Title) ? "Internship opportunity" : item.Title,
                        companyName = string.IsNullOrWhiteSpace(item.CompanyName) ? "Training provider" : item.CompanyName,
                        location = string.IsNullOrWhiteSpace(item.Location) ? "Location not specified" : item.Location,
                        major = item.Majors == null || item.Majors.Count == 0
                            ? "Various majors" : string.Join(", ", item.Majors),
                        seatsLeft = item.SeatsLeft,
                        deadline = FormatDeadline(item.ApplicationDeadline)
                    });
                }

                message = opportunities.Count == 0
                    ? "No open internship opportunities are currently available."
                    : "Current internship opportunities from Firebase. Showing the latest "
                        + opportunities.Count.ToString(CultureInfo.InvariantCulture) + ".";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceWarning("Home opportunities read failed ({0}).", ex.GetType().Name);
                message = IsSignedIn
                    ? "Unable to load internship opportunities. Please refresh, or sign in again if your session has expired."
                    : "Sign in to view internship opportunities. Public listings are currently unavailable.";
            }

            PublicDataJson = JsonConvert.SerializeObject(new
            {
                isAuthenticated = IsSignedIn,
                canApply = IsSignedIn && AuthHelper.UserRole == AuthHelper.RoleStudent,
                loginUrl = ResolveUrl("~/login/Login.aspx"),
                dashboardUrl = DashboardHref,
                applyUrl = ResolveUrl("~/Student/ApplicationForm/ApplicationForm.aspx"),
                opportunities = opportunities,
                message = message
            }, new JsonSerializerSettings { StringEscapeHandling = StringEscapeHandling.EscapeHtml });
        }

        private static string FormatDeadline(long milliseconds)
        {
            if (milliseconds <= 0) return "Not specified";
            try
            {
                return DateTimeOffset.FromUnixTimeMilliseconds(milliseconds)
                    .UtcDateTime.ToString("dd MMM yyyy", CultureInfo.InvariantCulture);
            }
            catch (ArgumentOutOfRangeException) { return "Not specified"; }
        }
    }
}
