using System;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Student.Data;

namespace UniversityInternshipManagmentSystem.Student
{
    public class StudentPage : Page
    {
        public StudentWorkspace Workspace { get; protected set; }
        public string DataError { get; protected set; }
        public string DisplayName => Show(Workspace?.Profile?.Student?.Name, "Student");
        public string ModeLabel => Workspace == null ? "Sign-in required" : "Authenticated student";
        public string CsrfToken => (string)Session["Student.Csrf"];

        protected override void OnInit(EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
            if (Session["Student.Csrf"] == null) Session["Student.Csrf"] = Guid.NewGuid().ToString("N");
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            base.OnInit(e);
        }

        protected async Task LoadWorkspaceAsync()
        {
            try { Workspace = await StudentModule.OpenAsync(new HttpContextWrapper(Context)); }
            catch (UnauthorizedAccessException ex) { DataError = ex.Message; }
            catch (StudentDataException ex) { DataError = ex.Message; }
            catch (Exception) { DataError = "Student information is temporarily unavailable. Please try again later."; }
        }

        protected override void OnPreRender(EventArgs e)
        {
            // Set only this Student page's title; the shared master remains unchanged.
            if (Header != null)
                Header.Title = (this is StudentProfilePage.Profile ? "My Profile" : "Student Dashboard") + " | The University of Jordan";
            base.OnPreRender(e);
        }
        public string Show(string value, string empty = "Not provided") => string.IsNullOrWhiteSpace(value) ? empty : value;
    }
}
