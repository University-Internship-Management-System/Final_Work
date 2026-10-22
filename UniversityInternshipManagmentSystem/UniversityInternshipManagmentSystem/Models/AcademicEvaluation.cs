using System;

namespace UniversityInternshipManagmentSystem.Models
{
    public class AcademicEvaluation
    {
        public const string Draft = "Draft";
        public const string Sent = "Sent";

        public string StudentId { get; set; }
        public string AcademicSupervisorId { get; set; }
        public string CompanyId { get; set; }
        public string Comments { get; set; }
        public bool IsPassAcademic { get; set; }
        public string Status { get; set; } = Draft;
        public DateTime? UpdatedAt { get; set; }
        public DateTime? SentAt { get; set; }
    }
}
