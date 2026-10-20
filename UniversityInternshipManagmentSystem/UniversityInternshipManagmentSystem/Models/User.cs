using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace UniversityInternshipManagmentSystem.Models
{
    public abstract class User
    {
        [JsonIgnore]
        public string Id { get; set; }

        public string Name { get; set; }

        public string Role { get; set; }

        public string Email { get; set; }

        public bool FirstLogin { get; set; }

        public string PhoneNumber { get; set; }

        public string ProfilePicUrl { get; set; }

        public User()
        {

        }

        public User(string name, string role, string email, bool firstLogin, string phoneNumber, string profilePic)
        {
            Name = name;
            Role = role;
            Email = email;
            FirstLogin = firstLogin;
            PhoneNumber = phoneNumber;
            ProfilePicUrl = profilePic;
        }
    }
}