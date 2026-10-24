# Team key files (for TESTING only)

These two files are read by the site. They are committed on purpose, so every team member gets them with `git pull`
(the same idea as the SMTP settings in `Web.config`).

| File to add here | What it is for | Where to get it |
|---|---|---|
| `firebase-admin.json` | Company supervisors: show and change their sign-in status. Deadline alert emails. | Firebase console -> Project settings -> Service accounts -> **Generate new private key**. Save the downloaded file with this name. |
| `cloudinary.json` | Coordinator profile photo upload | Cloudinary dashboard -> Settings -> API Keys. Copy `cloudinary.example.json`, fill in the three values. |

## How to edit them
Open the file in Visual Studio, change the value, save, then commit and push. Everybody gets it after `git pull`. Restart the site after a change.

## Rules
- Keep the repository **private**. Anyone who can read it can control the Firebase project and the Cloudinary account.
- A key in a Windows variable still wins over these files (`UIMS_FIREBASE_ADMIN_CREDENTIALS`, `UIMS_CLOUDINARY_CREDENTIALS`), so one PC can use a different key.
- Before a real deployment: delete the committed files, create **new** keys (the old ones stay in Git history), and keep them outside Git.
