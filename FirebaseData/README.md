# Firebase sample data

| File | What it is |
|---|---|
| `seed.json` | The whole sample database: students, companies, academic supervisors, opportunities, applications, tasks (with hours), submissions and final evaluations. **It also holds the real team accounts**, so importing it does not break anybody's login. The phone numbers of the real accounts are hidden (`0790000000`). |
| `opportunities-seed.json` | Only the `Opportunities` node of `seed.json`. |

## Why the accounts are inside the file
A login only works when the person has a record in the database under the same id as the Firebase account
(`Students/<uid>`, `CompanySupervisors/<uid>`, `AcademicSupervisors/<uid>`). The passwords are not in this file,
they stay in Firebase Authentication. If a record is missing the login falls back to "student".

## How to import
1. Firebase console -> Realtime Database -> the top (root) row -> Import JSON -> `seed.json`.
2. **Importing replaces everything in the database.** Anything created after the file was made (new accounts,
   new tasks, edits) is lost. Export the live data first if you are not sure.
3. A new account is NOT in this file. Create it again after the import, or ask Wadea to refresh the seed.

## Rules the data follows (keep them when you add data)
- A trainee of a company = a student whose `CompanyId` is that company. A task can only go to its company's trainees.
- A confirmed application = the application `Status` is `Confirmed` + the student is in the opportunity's `ConfirmedStudents` + the student has the company in `CompanyId`.
- Every task has `Hours`. One trainee has at most 15 hours of open tasks in one week. `StudentHours` holds only the trainees whose hours differ from `Hours`.
- The newest submission of a student decides the state of the task. Older versions are `RevisionRequested`.
- A final evaluation lives in `FinalEvaluations/<student id>`: the signed weeks (`ApprovedWeeks`: `w1` = hours), the 6 skill ratings, the dates and the `Status` (`Draft` or `Sent`). Only the trainee's own company can create it. A `Sent` one is final.
