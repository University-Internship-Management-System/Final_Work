using Newtonsoft.Json;
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
    }
}
