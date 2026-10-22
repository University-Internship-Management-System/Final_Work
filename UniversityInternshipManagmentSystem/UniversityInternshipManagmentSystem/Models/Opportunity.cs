using Newtonsoft.Json;
using System.Collections.Generic;
using System;
using System.Linq;
using System.Web;
namespace UniversityInternshipManagmentSystem.Models
{
    public class Opportunity
    {
        [JsonIgnore]
        public string Id { get; set; }
        public string CompanyId { get; set; }
        public string CompanyName { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Location { get; set; }

        public List<string> Majors { get; set; } = new List<string>();

        public int Seats { get; set; }
        public string Status { get; set; }
        public long CreatedAt { get; set; }


        public long ApplicationDeadline { get; set; }

        public Dictionary<string, bool> ConfirmedStudents { get; set; } = new Dictionary<string, bool>();

        public Opportunity() { }

        public Opportunity(string companyId, string companyName, string title, string description,
                           string location, List<string> majors, int seats, string status,
                           long createdAt, long applicationDeadline)
        {
            CompanyId = companyId;
            CompanyName = companyName;
            Title = title;
            Description = description;
            Location = location;
            Majors = majors ?? new List<string>();
            Seats = seats;
            Status = status;
            CreatedAt = createdAt;
            ApplicationDeadline = applicationDeadline;
        }

        [JsonIgnore]
        public bool IsDeadlinePassed
        {
            get
            {
                return ApplicationDeadline > 0
                    && System.DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() > ApplicationDeadline;
            }
        }

        [JsonIgnore]
        public bool IsOpenForApplications
        {
            get { return WhyClosed() == null; }
        }

        [JsonIgnore]
        public int SeatsLeft
        {
            get
            {
                int taken = ConfirmedStudents == null ? 0 : ConfirmedStudents.Count;
                int left = Seats - taken;
                return left < 0 ? 0 : left;
            }
        }

        // Why this opportunity does not take applications right now, or null when it does
        public string WhyClosed()
        {
            if (!string.Equals(Status, OpportunityStatus.Open, StringComparison.OrdinalIgnoreCase)) return "This opportunity is closed.";
            if (IsDeadlinePassed) return "The application deadline has passed.";
            if (SeatsLeft <= 0) return "There are no seats left.";
            return null;
        }

        // True when this opportunity lists the major (ignores capital letters and extra spaces)
        public bool AcceptsMajor(string major)
        {
            if (string.IsNullOrWhiteSpace(major) || Majors == null) return false;
            return Majors.Any(m => m != null && string.Equals(m.Trim(), major.Trim(), StringComparison.OrdinalIgnoreCase));
        }
    }

    public static class OpportunityStatus
    {
        public const string Open = "open";
        public const string Closed = "closed";
    }
}