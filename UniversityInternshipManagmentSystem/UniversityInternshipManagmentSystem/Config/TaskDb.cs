using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Config
{
    // Everything the student task pages need from Firebase.
    // Tables used: "Tasks", "TaskSubmissions", "CompanySupervisors"
    public static class TaskDb
    {
        // All tasks that were given to this student
        public static async Task<List<Tasks>> GetMyTasks(string studentId)
        {
            string json = await FirebaseDb.Get("Tasks");

            // Firebase returns the text "null" when the table is empty
            Dictionary<string, Tasks> all = JsonConvert.DeserializeObject<Dictionary<string, Tasks>>(json)
                                            ?? new Dictionary<string, Tasks>();

            List<Tasks> mine = new List<Tasks>();
            foreach (var item in all)
            {
                item.Value.TaskId = item.Key;          // the key is the id
                if (item.Value.StudentIds != null && item.Value.StudentIds.Contains(studentId))
                    mine.Add(item.Value);
            }
            return mine;
        }

        // Every version of this student's work, for all tasks
        public static async Task<List<TaskSubmission>> GetMySubmissions(string studentId)
        {
            string json = await FirebaseDb.Get("TaskSubmissions");

            Dictionary<string, TaskSubmission> all = JsonConvert.DeserializeObject<Dictionary<string, TaskSubmission>>(json)
                                                     ?? new Dictionary<string, TaskSubmission>();

            List<TaskSubmission> mine = new List<TaskSubmission>();
            foreach (var item in all)
            {
                item.Value.Id = item.Key;
                if (item.Value.StudentId == studentId)
                    mine.Add(item.Value);
            }
            return mine;
        }

        // companyId -> company name (the Tasks table only stores the id)
        public static async Task<Dictionary<string, string>> GetCompanyNames(List<Tasks> tasks)
        {
            Dictionary<string, string> names = new Dictionary<string, string>();
            foreach (Tasks task in tasks)
            {
                if (task.CompanyId == null || names.ContainsKey(task.CompanyId)) continue;

                string json = await FirebaseDb.Get("CompanySupervisors", task.CompanyId);
                CompanySupervisor company = JsonConvert.DeserializeObject<CompanySupervisor>(json);
                names[task.CompanyId] = company != null ? company.CompanyName : "Unknown company";
            }
            return names;
        }

        // Adds a NEW version. Returns false if Firebase refused it.
        public static async Task<bool> SaveSubmission(TaskSubmission submission)
        {
            HttpResponseMessage response = await FirebaseDb.Post("TaskSubmissions", submission);
            return response.IsSuccessStatusCode;
        }

        // ---------------------------------------------------------------------
        // Company supervisor side (Company/ManageTasks pages)
        // ---------------------------------------------------------------------

        // All tasks that this company created
        public static async Task<List<Tasks>> GetCompanyTasks(string companyId)
        {
            string json = await FirebaseDb.Get("Tasks");

            Dictionary<string, Tasks> all = JsonConvert.DeserializeObject<Dictionary<string, Tasks>>(json)
                                            ?? new Dictionary<string, Tasks>();

            List<Tasks> mine = new List<Tasks>();
            foreach (var item in all)
            {
                item.Value.TaskId = item.Key;
                if (item.Value.CompanyId == companyId)
                    mine.Add(item.Value);
            }
            return mine;
        }

        // studentId -> student (all students; each page picks the ones it needs)
        public static async Task<Dictionary<string, Models.Student>> GetStudents()
        {
            string json = await FirebaseDb.Get("Students");

            Dictionary<string, Models.Student> all = JsonConvert.DeserializeObject<Dictionary<string, Models.Student>>(json)
                                                     ?? new Dictionary<string, Models.Student>();

            foreach (var item in all)
                item.Value.Id = item.Key;
            return all;
        }

        // Every submission (all versions, all students) of the given tasks
        public static async Task<List<TaskSubmission>> GetSubmissionsOfTasks(List<Tasks> tasks)
        {
            string json = await FirebaseDb.Get("TaskSubmissions");

            Dictionary<string, TaskSubmission> all = JsonConvert.DeserializeObject<Dictionary<string, TaskSubmission>>(json)
                                                     ?? new Dictionary<string, TaskSubmission>();

            List<TaskSubmission> result = new List<TaskSubmission>();
            foreach (var item in all)
            {
                item.Value.Id = item.Key;
                foreach (Tasks task in tasks)
                {
                    if (task.TaskId == item.Value.TaskId)
                    {
                        result.Add(item.Value);
                        break;
                    }
                }
            }
            return result;
        }

        // Adds a new task. Returns false if Firebase refused it.
        public static async Task<bool> SaveTask(Tasks task)
        {
            HttpResponseMessage response = await FirebaseDb.Post("Tasks", task);
            return response.IsSuccessStatusCode;
        }

        // Saves the changes of an existing task (Status and CompanyId are not touched)
        public static async Task<bool> UpdateTask(Tasks task)
        {
            var data = new { task.TaskName, task.TaskDescription, task.WeekNumber, task.StartDate, task.DeadLine, task.StudentIds, task.ToolsUsed, task.MaxScore, task.Hours, task.StudentHours };
            HttpResponseMessage response = await FirebaseDb.Patch("Tasks", task.TaskId, data);
            return response.IsSuccessStatusCode;
        }

        // ---------------------------------------------------------------------
        // Final evaluation (Company/FinalEvaluation pages). Table: "FinalEvaluations", the key is the student id.
        // ---------------------------------------------------------------------

        // The records of this company's trainees: studentId -> record
        public static async Task<Dictionary<string, FinalEvaluation>> GetFinalEvaluations(string companyId)
        {
            string json = await FirebaseDb.Get("FinalEvaluations");

            Dictionary<string, FinalEvaluation> all = JsonConvert.DeserializeObject<Dictionary<string, FinalEvaluation>>(json)
                                                      ?? new Dictionary<string, FinalEvaluation>();

            Dictionary<string, FinalEvaluation> mine = new Dictionary<string, FinalEvaluation>();
            foreach (var item in all)
            {
                item.Value.StudentId = item.Key;
                if (item.Value.CompanyId == companyId)
                    mine[item.Key] = item.Value;
            }
            return mine;
        }

        // Saves the whole record of one trainee (it replaces the old one)
        public static async Task<bool> SaveFinalEvaluation(string studentId, FinalEvaluation evaluation)
        {
            HttpResponseMessage response = await FirebaseDb.Put("FinalEvaluations", studentId, evaluation);
            return response.IsSuccessStatusCode;
        }

        // Open or close a task (only the Status field changes)
        public static async Task<bool> SetTaskStatus(string taskId, TaskState status)
        {
            HttpResponseMessage response = await FirebaseDb.Patch("Tasks", taskId, new { Status = status.ToString() });
            return response.IsSuccessStatusCode;
        }

        // The supervisor's decision on one submission: Evaluated (with a score) or RevisionRequested
        public static async Task<bool> SaveEvaluation(string submissionId, SubmissionState status, double? score, string feedback)
        {
            var data = new { Status = status.ToString(), Score = score, Feedback = feedback, EvaluatedAt = DateTime.Now };
            HttpResponseMessage response = await FirebaseDb.Patch("TaskSubmissions", submissionId, data);
            return response.IsSuccessStatusCode;
        }
    }
}
