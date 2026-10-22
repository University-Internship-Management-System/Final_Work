using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public class AcademicSupervisor : User
    {
        public string UniversityEmail { get; set; }

        public string Major { get; set; }

        public AcademicSupervisor()
        {

        }

        public AcademicSupervisor(string name, string email, bool firstLogin,string phoneNumber, string profilePic,string universityEmail, string major) : base(name, "AcademicSupervisor", email, firstLogin, phoneNumber, profilePic)
        {
            UniversityEmail = universityEmail;
            Major = major;
        }
    }
}