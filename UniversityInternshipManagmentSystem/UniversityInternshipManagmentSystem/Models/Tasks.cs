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

        public Tasks()
        {

        }

        public Tasks(string taskId, string taskName, string taskDescription, TaskState status, DateTime startDate, DateTime deadLine, List<string> studentIds, string companyId, int weekNumber, string toolsUsed, double maxScore)
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
        }


    }
}