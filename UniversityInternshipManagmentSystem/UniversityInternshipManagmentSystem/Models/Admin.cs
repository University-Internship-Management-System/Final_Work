using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public class Admin : User
    {
        public Admin() { }

        public Admin(string name, string role, string email, bool firstLogin,string phoneNumber, string profilePic) : base(name, role, email, firstLogin, phoneNumber, profilePic)
        {

        }
    }
}