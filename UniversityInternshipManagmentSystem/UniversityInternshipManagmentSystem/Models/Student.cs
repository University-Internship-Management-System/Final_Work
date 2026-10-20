
using System.Collections.Generic;

namespace UniversityInternshipManagmentSystem.Models
{
    public class Student : User
    {
        public string UniEmail { get; set; }
        public string Major { get; set; }
        public string CompanyId { get; set; }
        public string AcademicSupervisorId { get; set; }
        public double GPA { get; set; }
        public string CvUrl { get; set; }
        public string PortfolioUrl { get; set; }

        public List<string> SkillsList { get; set; }
            = new List<string>();

        // Default Constructor
        public Student() { }

        // Parameterized Constructor
        public Student(
            string name,
            string email,
            bool firstLogin,
            string phoneNumber,
            string profilePic,
            string uniEmail,
            string major,
            string companyId,
            string academicSupervisorId,
            double gpa,
            string cvUrl,
            string portfolioUrl,
            List<string> skillsList
        ) : base(
            name,
            "Student",
            email,
            firstLogin,
            phoneNumber,
            profilePic)
        {
            UniEmail = uniEmail;
            Major = major;
            CompanyId = companyId;
            AcademicSupervisorId = academicSupervisorId;
            GPA = gpa;
            CvUrl = cvUrl;
            PortfolioUrl = portfolioUrl;
            SkillsList = skillsList ?? new List<string>();
        }
    }
}
