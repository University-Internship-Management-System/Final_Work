using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using StudentModel = UniversityInternshipManagmentSystem.Models.Student;
using ApplicationModel = UniversityInternshipManagmentSystem.Models.Application;

namespace UniversityInternshipManagmentSystem.Academic
{
    public partial class Dashboard : Page
    {
        protected Panel workspace, noticePanel, emptyPanel;
        protected Literal notice, supervisorMajor, totalCount, confirmedCount, waitingCount;
        protected TextBox studentSearch;
        protected Repeater students;
        private Dictionary<string, StudentModel> assigned;
        private Dictionary<string, ApplicationModel> confirmed;
        private Dictionary<string, CompanySupervisor> companies;
        private AcademicSupervisor supervisor;

        protected void Page_Init(object sender, EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
        }

        protected async void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic);
            if (Response.IsRequestBeingRedirected) return;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowError("Sign in with a real academic supervisor account to view your students.");
                return;
            }
            try
            {
                var supervisors = await ReadTable<AcademicSupervisor>("AcademicSupervisors");
                string supervisorId = AuthHelper.UserId;
                if (!supervisors.TryGetValue(supervisorId, out supervisor))
                {
                    var matches = supervisors.Where(item => String.Equals(item.Value.Email, AuthHelper.UserEmail,
                        StringComparison.OrdinalIgnoreCase) && !String.IsNullOrWhiteSpace(AuthHelper.UserEmail)).ToList();
                    if (matches.Count != 1)
                    {
                        ShowError("Your academic supervisor profile could not be identified. Contact the coordinator.");
                        return;
                    }
                    supervisorId = matches[0].Key;
                    supervisor = matches[0].Value;
                }
                var allStudents = await ReadTable<StudentModel>("Students");
                assigned = allStudents.Where(item => item.Value.AcademicSupervisorId == supervisorId && SameMajor(item.Value.Major))
                    .ToDictionary(item => item.Key, item => item.Value);
                var applications = await ReadTable<ApplicationModel>("Applications");
                confirmed = applications.Values.Where(item => assigned.ContainsKey(item.StudentId ?? "")
                    && item.Status == ApplicationStatus.Confirmed).GroupBy(item => item.StudentId)
                    .ToDictionary(group => group.Key, group => group.OrderByDescending(item => item.ConfirmedAt).First());
                companies = await ReadTable<CompanySupervisor>("CompanySupervisors");
                litAcademicName.Text = Server.HtmlEncode(supervisor.Name);
                supervisorMajor.Text = supervisor.Major;
                totalCount.Text = assigned.Count.ToString();
                confirmedCount.Text = confirmed.Count.ToString();
                waitingCount.Text = (assigned.Count - confirmed.Count).ToString();
                // Trigger C# search after typing pauses, without reloading the page.
                studentSearch.Attributes["oninput"] = "clearTimeout(window.adSearchTimer);window.adSearchTimer=setTimeout(function(){__doPostBack(\""
                    + studentSearch.UniqueID + "\",\"\");},300);";
                workspace.Visible = true;
                BindStudents();
            }
            catch
            {
                ShowError("Could not load the dashboard. Check your connection or sign in again.");
            }
        }

        private async Task<Dictionary<string, T>> ReadTable<T>(string table)
        {
            string json = await FirebaseDb.Get(table);
            if (json == null) throw new HttpRequestException();
            return JsonConvert.DeserializeObject<Dictionary<string, T>>(json) ?? new Dictionary<string, T>();
        }

        private bool SameMajor(string major)
        {
            return String.Equals((major ?? "").Trim(), (supervisor.Major ?? "").Trim(), StringComparison.OrdinalIgnoreCase);
        }

        private void BindStudents()
        {
            string query = studentSearch.Text.Trim();
            var rows = assigned.OrderBy(item => item.Value.Name).Select(item =>
            {
                ApplicationModel placement;
                confirmed.TryGetValue(item.Key, out placement);
                CompanySupervisor company = null;
                if (placement != null) companies.TryGetValue(placement.CompanyId ?? "", out company);
                return new
                {
                    item.Value.Name, item.Value.UniEmail, item.Value.Major,
                    Company = placement == null ? "Not confirmed" : company != null ? company.CompanyName : placement.CompanyName,
                    Opportunity = placement == null ? "" : placement.OpportunityTitle,
                    ProgressUrl = ResolveUrl("~/Academic/StudentProgress/StudentProgress.aspx")
                        + "?studentId=" + Server.UrlEncode(item.Key)
                };
            }).Where(item => (query == "" || ((item.Name ?? "") + " " + (item.UniEmail ?? "") + " " + (item.Company ?? ""))
                    .IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0)).ToList();
            students.DataSource = rows;
            students.DataBind();
            emptyPanel.Visible = rows.Count == 0;
        }

        private void ShowError(string text)
        {
            workspace.Visible = false;
            noticePanel.Visible = true;
            notice.Text = text;
        }
    }
}
