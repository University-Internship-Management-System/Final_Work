using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public enum SubmissionState { Submitted, RevisionRequested, Evaluated }

    public class TaskSubmission
    {
        [JsonIgnore] public string Id { get; set; }
        public string TaskId { get; set; }
        public string StudentId { get; set; }
        public int Version { get; set; }
        public string Description { get; set; }
        public string Link { get; set; }
        public DateTime SubmittedAt { get; set; }
        public bool IsLate { get; set; }
        [JsonConverter(typeof(StringEnumConverter))]
        public SubmissionState Status { get; set; }
        public string Feedback { get; set; }
        public double? Score { get; set; }
        public DateTime? EvaluatedAt { get; set; }


        public TaskSubmission()
        {

        }

        public TaskSubmission(string taskId, string studentId, int version,
                              string description, string link, DateTime deadLine)
        {
            TaskId = taskId;
            StudentId = studentId;
            Version = version;
            Description = description;
            Link = link;
            SubmittedAt = DateTime.Now;
            IsLate = SubmittedAt > deadLine;
            Status = SubmissionState.Submitted;
        }
    }

}