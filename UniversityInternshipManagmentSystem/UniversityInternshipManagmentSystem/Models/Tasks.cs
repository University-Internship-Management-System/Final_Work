using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public enum TaskState { Open, Closed}
    public class Tasks
    {
        [JsonIgnore]
        public string TaskId { get; set; }

        public string TaskName { get; set; }

        public string TaskDescription { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public TaskState Status { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime DeadLine { get; set; }

        public List<string> StudentIds { get; set; } = new List<string>();

        public string CompanyId { get; set; }

        public int WeekNumber { get; set; }

        public string ToolsUsed { get; set; }

        public double MaxScore { get; set; }

        // The weight of the task = how many training hours it stands for.
        // The tasks of one week must not add up to more than 15 hours for one student.
        public int Hours { get; set; }

        // Only the trainees whose hours are DIFFERENT from Hours: studentId -> hours. Everybody else uses Hours.
        public Dictionary<string, int> StudentHours { get; set; } = new Dictionary<string, int>();

        public Tasks()
        {

        }

        public Tasks(string taskId, string taskName, string taskDescription, TaskState status, DateTime startDate, DateTime deadLine, List<string> studentIds, string companyId, int weekNumber, string toolsUsed, double maxScore, int hours)
        {
            TaskId = taskId;
            TaskName = taskName;
            TaskDescription = taskDescription;
            Status = status;
            StartDate = startDate;
            DeadLine = deadLine;
            StudentIds = studentIds ?? new List<string>();
            CompanyId = companyId;
            WeekNumber = weekNumber;
            ToolsUsed = toolsUsed;
            MaxScore = maxScore;
            Hours = hours;
        }

        // The hours of this task for ONE trainee: his own number if he has one, otherwise the default
        public int HoursFor(string studentId)
        {
            if (StudentHours != null && StudentHours.ContainsKey(studentId))
                return StudentHours[studentId];
            return Hours;
        }

        // "3 hours", or "4 to 8 hours" when the trainees have different hours
        public string HoursText()
        {
            int min = Hours, max = Hours;
            foreach (string studentId in StudentIds)
            {
                int h = HoursFor(studentId);
                if (h < min) min = h;
                if (h > max) max = h;
            }
            if (max == 0) return "No hours set";
            if (min == max) return max + (max == 1 ? " hour" : " hours");
            return min + " to " + max + " hours";
        }


    }
}