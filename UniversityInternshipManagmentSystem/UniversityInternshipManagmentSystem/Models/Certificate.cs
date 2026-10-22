using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public class Certificate
    {
        public string CertificateId { get; set; }
        public string StudentId { get; set; }
        public string OpportunityId { get; set; }
        public List<string> TaskId { get; set; }
            = new List<string>();
        public bool IsPassAdmin { get; set; }
        public bool IsPassCompany { get; set; }
        public bool IsPassAcademic { get; set; }

        public Certificate()
        {

        }

        public Certificate(string certificateId, string studentId, string opportunityId, List<string> taskId, bool isPassAdmin, bool isPassCompany, bool isPassAcademic)
        {
            CertificateId = certificateId;
            StudentId = studentId;
            OpportunityId = opportunityId;
            TaskId = taskId;
            IsPassAdmin = isPassAdmin;
            IsPassCompany = isPassCompany;
            IsPassAcademic = isPassAcademic;
        }
    }
}