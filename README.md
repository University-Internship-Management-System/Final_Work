## Project Links

- **GitHub Repository:** [University Internship Management System](https://github.com/University-Internship-Management-System/University-Internship-Management-System-)
- **Trello Board:** [Project Planning & Task Management](https://trello.com/b/oyIBEBfI/university-internship-management-system)
- **Figma Design:** [UIMS UI/UX Design](https://www.figma.com/design/yGEcZwNwcLNDdSBNeLai7i/UIMS-—-Wireframes--Mockups---Prototype?node-id=65-13990&t=xDOKa1f6c3XZha8v-1)
- **Live Demo:** [Live Demo](https://wadea7-001-site1.dtempurl.com/)

# University Internship Management System — UIMS

UIMS is a web application that manages the university field training process for the King Abdullah II School of Information Technology (KASIT) at the University of Jordan.

The system connects students, company supervisors, academic supervisors, and university coordinators in one platform, covering internship opportunities, applications, training tasks, progress tracking, final evaluations, and completion approval.

Developed during our training experience at **Orange**.

## User Roles & Features

### Student

- Browse internship opportunities and submit applications.
- Track application status.
- Manage personal and training information.
- View assigned weekly tasks and submit work.
- Track task submission progress across six training weeks.
- View the completion certificate after coordinator approval.

### Company Supervisor

- Publish and manage internship opportunities.
- Review student applications.
- Manage assigned trainees.
- Create training tasks and review submissions.
- Submit final training evaluations.

### Academic Supervisor

- Monitor assigned students and their training progress.
- Review student training information.
- Submit academic final evaluations.

### University Coordinator

- Manage students, company supervisors, and academic supervisors.
- Assign academic supervisors to students.
- Monitor internship progress.
- Review final completion requirements.
- Approve training completion and certificate availability.
- Review contact messages.

## Progress Tracking

The training journey uses **task submission completion**, rather than elapsed time.

- A week is marked **Completed** when all its assigned tasks have a latest submission with a status of **Submitted** or **Evaluated**.
- A week with no assigned tasks is not counted as completed.
- The first assigned week with unfinished tasks is marked **In progress**.
- Each week's submission percentage is calculated as:

  `Submitted tasks ÷ Assigned tasks × 100`

- Completing tasks does not automatically grant a passing result or unlock the certificate. University coordinator approval is still required.

## Technology Stack

| Layer | Technologies |
|---|---|
| Backend | C#, ASP.NET Web Forms |
| Framework | .NET Framework 4.8 |
| Frontend | HTML, CSS, JavaScript |
| UI Libraries | Bootstrap 5, Bootstrap Icons, jQuery |
| Authentication | Firebase Authentication |
| Database | Firebase Realtime Database |
| JSON Processing | Newtonsoft.Json |
| Development | Visual Studio, NuGet, IIS Express |
| Design & Planning | Figma, Trello |

## Getting Started

### Requirements

- Windows.
- Visual Studio with the **ASP.NET and web development** workload.
- .NET Framework 4.8 Developer Pack.
- IIS Express.
- Access to the project's Firebase configuration.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/University-Internship-Management-System/University-Internship-Management-System-.git
   ```

2. Open the solution in Visual Studio.

3. Restore the NuGet packages.

4. Configure the application settings for your environment:
   - Firebase API key and Realtime Database URL.
   - SMTP settings if email functionality is required.
   - Use a local `secrets.config` file for private configuration values.

5. Set the web project as the startup project.

6. Build the solution.

7. Run the application using IIS Express.

8. Open `index.aspx` through the address provided by Visual Studio.

> Keep passwords, tokens, and private configuration values out of version control.

## Project Structure

```text
UniversityInternshipManagmentSystem/
└── UniversityInternshipManagmentSystem/
    ├── Academic/       # Academic supervisor pages
    ├── Company/        # Company supervisor pages
    ├── Coordinator/    # University coordinator pages
    ├── Student/        # Student pages and training workflow
    ├── PoweredBy/      # Team page, portraits, and profile links
    ├── Shared/         # Shared layouts, navigation, and footer
    ├── Config/         # Application configuration and helpers
    ├── Models/         # Data models
    ├── Content/        # Stylesheets
    ├── Scripts/        # JavaScript files
    ├── Assets/         # Images and other assets
    ├── login/          # Authentication pages
    ├── index.aspx      # Public landing page
    └── Web.config      # Application configuration
```

## Our Team

| Team Member | Role | GitHub | LinkedIn | Portfolio |
|---|---|---|---|---|
| Abdallah Mdalal | Developer | [GitHub](https://github.com/abd3348) | [LinkedIn](https://www.linkedin.com/in/abdallah-mdalal) | [Portfolio](https://abd3348.github.io/Portfolio/) |
| Marwa Albadarneh | Scrum Master | [GitHub](https://github.com/MarwaM5) | [LinkedIn](https://www.linkedin.com/in/marwa-albadarneh) | [Portfolio](https://marwam5.github.io/My-Portfolio/) |
| Yaqeen Jawabreh | Developer | [GitHub](https://github.com/yaqeenjawabreh) | [LinkedIn](https://www.linkedin.com/in/yaqeenjawabreh/) | Coming soon |
| Lujain Okour | QA | [GitHub](https://github.com/lujainokour) | [LinkedIn](https://www.linkedin.com/in/lujain-okour-06903b313/) | Coming soon |
| Wadea | Developer | [GitHub](https://github.com/WadeaYH) | [LinkedIn](https://www.linkedin.com/in/wadea-yh-2188b6278/) | [Portfolio](https://wadeayh.github.io/WadeaPortfolio/) |
| Omar Alsmadi | Developer | [GitHub](https://github.com/omarsk2003) | [LinkedIn](https://www.linkedin.com/in/omarkamalalsmadi/) | Coming soon |
| Ala'a Frihat | Product Owner | [GitHub](https://github.com/AlaaFrihat) | [LinkedIn](https://www.linkedin.com/in/ala-a-frihat-8149a53b3) | [Portfolio](https://alaafrihat.github.io/project/) |

The **Powered by** page presents the team with interactive portraits and profile links. It is accessible from the shared footer and the landing page footer.

## Acknowledgements

- **The University of Jordan**
- **King Abdullah II School of Information Technology — KASIT**
- **Orange**
