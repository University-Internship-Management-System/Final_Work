using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
namespace UniversityInternshipManagmentSystem.Models
{
    public class Application
    {
        [JsonIgnore]
        public string Id { get; set; }

        public string StudentId { get; set; }
        public string OpportunityId { get; set; }
        public string CompanyId { get; set; }

        public string OpportunityTitle { get; set; }
        public string CompanyName { get; set; }

        public string CvUrl { get; set; }
        public string PortfolioUrl { get; set; }
        public string CoverLetter { get; set; }

        public string Status { get; set; }
        public string RejectionReason { get; set; }

        public long AppliedAt { get; set; }
        public long ReviewedAt { get; set; }
        public long ConfirmedAt { get; set; }

        public Application() { }

        public Application(string studentId, string opportunityId, string companyId,
                           string opportunityTitle, string companyName,
                           string cvUrl, string portfolioUrl, string coverLetter,
                           long appliedAt)
        {
            StudentId = studentId;
            OpportunityId = opportunityId;
            CompanyId = companyId;
            OpportunityTitle = opportunityTitle;
            CompanyName = companyName;
            CvUrl = cvUrl;
            PortfolioUrl = portfolioUrl;
            CoverLetter = coverLetter;
            Status = ApplicationStatus.Pending;
            RejectionReason = "";
            AppliedAt = appliedAt;
        }
    }

    public static class ApplicationStatus
    {
        public const string Pending = "Pending";
        public const string Accepted = "Accepted";
        public const string Rejected = "Rejected";
        public const string Confirmed = "Confirmed";
    }
}