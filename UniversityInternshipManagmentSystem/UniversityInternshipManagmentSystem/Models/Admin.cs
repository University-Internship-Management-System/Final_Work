using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public class Admin : User
    {
        public Admin() { }

        public Admin(string name, string email, bool firstLogin,string phoneNumber, string profilePic) : base(name, "Admin", email, firstLogin, phoneNumber, profilePic)
        {

        }
    }
}