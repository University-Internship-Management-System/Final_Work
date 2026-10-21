using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace UniversityInternshipManagmentSystem.Student.Data
{
    // Property names intentionally match the existing Realtime Database JSON.
    public sealed class StudentRecord
    {
        public string Name { get; set; }
        public string Role { get; set; }
        public string Email { get; set; }
        public bool FirstLogin { get; set; }
        public string PhoneNumber { get; set; }
        public string ProfilePicUrl { get; set; }
        public string UniEmail { get; set; }
        public string Major { get; set; }
        public string CompanyId { get; set; }
        public string AcademicSupervisorId { get; set; }
        public decimal? GPA { get; set; }
        public string CvUrl { get; set; }
        public string PortfolioUrl { get; set; }
        public List<string> SkillsList { get; set; }
    }

    public sealed class StudentProfile
    {
        public StudentRecord Student { get; set; }
        public string CompanyName { get; set; }
        public string AcademicSupervisorName { get; set; }
    }

    // Authentication must construct this from a verified, server-side session.
    // Never populate it directly from query strings, posted IDs, or client claims.
    public sealed class StudentAccess
    {
        public string StudentId { get; set; }
        [JsonIgnore]
        public string FirebaseIdToken { get; set; }
        // Set only from a server-verified token, never from a posted student ID.
        public string FirebaseUid { get; set; }
        public DateTimeOffset ExpiresUtc { get; set; }
        public ISet<string> EditableFields { get; set; }
    }

    public sealed class StudentWorkspace
    {
        public IStudentRepository Repository { get; set; }
        public StudentProfile Profile { get; set; }
        public StudentAccess Access { get; set; }
        public bool IsDemo { get; set; }
        public bool CanEdit(string field)
        {
            return !IsDemo && Access != null && Access.ExpiresUtc > DateTimeOffset.UtcNow
                && !string.IsNullOrWhiteSpace(Access.FirebaseUid) && Access.EditableFields != null
                && Access.EditableFields.Contains(field) && ProfileValidation.EditableFields.Contains(field);
        }
    }

    // Optional adapter for the other modules: these are view models, NOT assumed Firebase nodes.
    public sealed class StudentActivity
    {
        public string Title { get; set; }
        public string Detail { get; set; }
        public string Status { get; set; }
        public DateTimeOffset? DueUtc { get; set; }
        // Evaluation adapters must explicitly opt in; missing flags remain confidential.
        public bool IsPublished { get; set; }
        public bool IsStudentVisible { get; set; }
    }

    public sealed class StudentOverview
    {
        public IList<StudentActivity> Applications { get; set; } = new List<StudentActivity>();
        public IList<StudentActivity> Tasks { get; set; } = new List<StudentActivity>();
        public IList<StudentActivity> Deadlines { get; set; } = new List<StudentActivity>();
        // The adapter MUST return published, student-visible evaluations only.
        public IList<StudentActivity> Evaluations { get; set; } = new List<StudentActivity>();
        public decimal? ApprovedHours { get; set; }
        public decimal? RequiredHours { get; set; }
        public string InternshipStatus { get; set; }

        public static StudentOverview ForStudent(StudentOverview source, DateTimeOffset now)
        {
            if (source == null) throw new StudentDataException("Activity information is unavailable.");
            return new StudentOverview
            {
                Applications = new List<StudentActivity>((source.Applications ?? new List<StudentActivity>()).Where(item => item != null)),
                Tasks = new List<StudentActivity>((source.Tasks ?? new List<StudentActivity>()).Where(item => item != null)),
                Deadlines = new List<StudentActivity>((source.Deadlines ?? new List<StudentActivity>()).Where(item => item != null && item.DueUtc.HasValue && item.DueUtc.Value >= now).OrderBy(item => item.DueUtc)),
                Evaluations = new List<StudentActivity>((source.Evaluations ?? new List<StudentActivity>()).Where(item => item != null && item.IsPublished && item.IsStudentVisible)),
                ApprovedHours = source.ApprovedHours >= 0 ? source.ApprovedHours : null,
                RequiredHours = source.RequiredHours > 0 ? source.RequiredHours : null,
                InternshipStatus = source.InternshipStatus
            };
        }

        public int? ProgressPercent
        {
            get
            {
                if (!ApprovedHours.HasValue || ApprovedHours < 0 || !RequiredHours.HasValue || RequiredHours <= 0) return null;
                if (ApprovedHours >= RequiredHours) return 100;
                return (int)decimal.Round((ApprovedHours.Value / RequiredHours.Value) * 100);
            }
        }
    }
}
