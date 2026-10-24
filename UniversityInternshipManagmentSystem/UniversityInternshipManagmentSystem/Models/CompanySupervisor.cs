
namespace UniversityInternshipManagmentSystem.Models
{
    public class CompanySupervisor : User
    {
        public string CompanyName { get; set; }
        public string CompEmail { get; set; }
        public string Location { get; set; }

        public CompanySupervisor() { }

        public CompanySupervisor(
            string name,
            string email,
            bool firstLogin,
            string phoneNumber,
            string profilePic,
            string companyName,
            string compEmail,
            string location
        ) : base(
            name,
            "CompanySupervisor",
            email,
            firstLogin,
            phoneNumber,
            profilePic)
        {
            CompanyName = companyName;
            CompEmail = email;
            Location = location;
        }
    }
}
