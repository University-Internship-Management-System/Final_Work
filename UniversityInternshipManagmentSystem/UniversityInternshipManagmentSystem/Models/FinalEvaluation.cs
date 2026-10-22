using Newtonsoft.Json;
using System;
using System.Collections.Generic;

namespace UniversityInternshipManagmentSystem.Models
{
    // One record per trainee in the "FinalEvaluations" node (the key is the student id).
    // It follows the university form "Practical training report" (SUJ-KASIT-03-01-02):
    //   page 1 = the weekly report (the supervisor of the training place signs every week)
    //   page 2 = the evaluation of the trainee's performance (6 skills, 5 levels), filled at the end of the training
    public class FinalEvaluation
    {
        public const string Draft = "Draft";      // the company supervisor is still working on it
        public const string Sent = "Sent";        // sent to the academic supervisor: it cannot be changed any more
        public const string AcademicDraft = "Draft";

        // The 6 skills of the form: key -> text
        public static readonly string[][] Skills = new[]
        {
            new[] { "Responsibility", "Taking responsibility" },
            new[] { "WorkingHours", "Keeping working hours" },
            new[] { "Accuracy", "Accuracy in work" },
            new[] { "Teamwork", "Working in a team" },
            new[] { "Adaptation", "Adapting to the work environment" },
            new[] { "LearningSpeed", "Speed of learning new skills" }
        };

        // The 5 levels of the form, from the best (5 points) to the worst (1 point): key -> text
        public static readonly string[][] Levels = new[]
        {
            new[] { "Excellent", "Excellent" },
            new[] { "VeryGood", "Very good" },
            new[] { "Good", "Good" },
            new[] { "Acceptable", "Acceptable" },
            new[] { "Weak", "Weak" }
        };

        [JsonIgnore]
        public string StudentId { get; set; }

        public string CompanyId { get; set; }

        // The weeks the supervisor signed: "w1" -> the hours of that week at the time of signing
        public Dictionary<string, int> ApprovedWeeks { get; set; } = new Dictionary<string, int>();

        // skill key -> level key, for example "Teamwork" -> "VeryGood"
        public Dictionary<string, string> Ratings { get; set; } = new Dictionary<string, string>();

        public string Comments { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        // The total training hours of the form = the hours of the signed weeks
        public int TotalHours { get; set; }

        public string Status { get; set; } = Draft;

        // Set when the company supervisor approves the completed internship and sends it to the academic supervisor.
        public bool IsPassCompany { get; set; }

        public DateTime? UpdatedAt { get; set; }

        public DateTime? SentAt { get; set; }

        // Academic review is stored on the same FinalEvaluations/{studentId} record.
        public string AcademicSupervisorId { get; set; }
        public string AcademicComments { get; set; }
        public bool IsPassAcademic { get; set; }
        public string AcademicEvaluationStatus { get; set; } = AcademicDraft;
        public DateTime? AcademicUpdatedAt { get; set; }
        public DateTime? AcademicSentAt { get; set; }

        // 5 points for Excellent ... 1 point for Weak
        public static int Points(string levelKey)
        {
            for (int i = 0; i < Levels.Length; i++)
                if (Levels[i][0] == levelKey) return 5 - i;
            return 0;
        }

        // "Very good (4.2 / 5)" when all 6 skills have a level, otherwise an empty text.
        // The university has not given a grade formula for this form, so this is only a simple average.
        public string OverallText()
        {
            if (Ratings == null || Ratings.Count < Skills.Length) return "";

            double sum = 0;
            foreach (string[] skill in Skills)
                sum += Points(Ratings.ContainsKey(skill[0]) ? Ratings[skill[0]] : "");
            double average = sum / Skills.Length;

            string level = average >= 4.5 ? "Excellent" : average >= 3.5 ? "Very good" : average >= 2.5 ? "Good" : average >= 1.5 ? "Acceptable" : "Weak";
            return level + " (" + average.ToString("0.0", System.Globalization.CultureInfo.InvariantCulture) + " / 5)";
        }
    }
}


