# My Trainees — official requirement implementation

## Requirement and retained integration
"Display accepted students, their training information, and their progress."

The existing page, code-behind, designer, CSS, JavaScript, Shared/Dashboard.Master and project registrations are retained.
Only files inside Company/MyTrainees are changed. No Firebase writes, new accounts, shared edits or configuration/rule changes are implemented.
PROJECT-REGISTRATION.patch is historical; all six runtime items are already registered. Do not apply it again.

## Company identity and Firebase access
The existing team AppConfig.DbUrl/ApiKey and Login session are reused. Every request verifies the token server-side through Firebase accounts:lookup, then checks UID, project, issuer, lifetime, disabled/revoked state, company role and the own CompanySupervisors record.
Ownership requires matching AuthUid, or a UID-keyed record when AuthUid is absent. Email alone never proves ownership.
No ID is accepted from the browser. The current authenticated company's actual record key is used; company_test_001 is never hardcoded into production.

At the user's explicit instruction, the module-local Application["Company.MyTrainees.ReadApproval"] gate and its approval class were removed.
Firebase Rules and verified company ownership remain mandatory. There is no server-side privilege escalation or administrator token.
Contact email disclosure has NOT been broadened; personal/university emails are not returned to the cards.

## Eligibility and deduplication
1. For the explicitly authorized small test dataset, read Applications.json with the verified supervisor ID token and NO orderBy/equalTo. Stream at most 512 KiB with a 15-second deadline; allow at most 1000 records and 100 eligible student IDs. Reject oversized, malformed, denied or timed-out reads. Filter CompanyId and Accepted/Confirmed statuses privately in C# before any Student reads or page binding. Foreign application records never reach the browser or ViewState.
2. Consider exact model statuses Accepted and Confirmed only. Pending/Rejected never cause a Student read.
3. Read only the application-linked Students/{StudentId} records with the same authenticated token, with bounded concurrency. Never fetch the whole Students collection.
4. Confirmed requires Student.CompanyId equal to the company key.
5. Accepted may have an empty CompanyId because the existing My Applications workflow assigns CompanyId on confirmation. Show "Accepted — awaiting confirmation"; do not call it a confirmed placement.
6. A Student assigned to another company is excluded, even with a stale Accepted application.
7. Emit one row per Student key. Prefer a valid Confirmed application, then choose deterministically by ConfirmedAt, ReviewedAt, AppliedAt and application key.

Denied required application/student reads show an unavailable error, not an empty list or partial success.

## Training fields
- Name/Major: Student record; honest placeholders when absent.
- Company: verified CompanySupervisors.CompanyName.
- Opportunity title: the selected Application.OpportunityTitle; if absent, attempt only the linked Opportunities/{OpportunityId}, using the same token and requiring its CompanyId to match.
- Status: selected Accepted/Confirmed application, visibly distinct.
- Confirmation date: selected Confirmed application's ConfirmedAt, Unix milliseconds displayed in UTC. Missing/invalid timestamps are unavailable. Accepted rows say awaiting confirmation.
- Academic supervisor: only assignment presence is shown. No supervisor-name/contact read is made without an approved access contract.
- Training hours: no authoritative approved-hours source was found, so no hours/approval totals are invented.

## Task progress contract reused from MyProgress
- Read Tasks with orderBy="CompanyId" and equalTo={verified company key}. Validate returned CompanyId values.
- A student's assigned tasks require StudentIds containing that Student key.
- Reuse the existing MyProgress window WeekNumber 1 through 6. This is the current team's task scope, not an inferred internship duration or hours policy.
- Read TaskSubmissions using orderBy="StudentId" and equalTo={eligible student key}, only when there are assigned tasks.
- Validate the returned student scope. Ignore submissions whose TaskId is outside the selected company's assigned tasks.
- Choose the latest submission per task by Version descending, then SubmittedAt descending. Use a deterministic record-key tiebreak.
- "Submitted / evaluated" counts latest status Submitted or Evaluated, matching MyProgress. A newer RevisionRequested submission does not count as submitted.
- "Evaluated" counts only latest Evaluated status. It is not an independent passed/completed-hours claim.
- Percentage = submitted/evaluated count divided by assigned task count, rounded AwayFromZero as MyProgress does.
- A successful empty task result means zero assigned tasks. Missing/denied/malformed task or submission data means Progress not available, never an invented zero.
- Optional progress/opportunity failures do not erase the authorized directory. Assigned count remains available when only submission reads fail.

## Required Firebase permissions/index support
The Firebase owner must permit the actual supervisor token to perform:
- Own CompanySupervisors/{recordKey} read.
- Authenticated full Applications collection read under the existing Rules. No Applications index is required by the current small-test implementation. If this broader read is denied, stop; do not use a privileged token.
- Direct reads of eligible application-linked Students, including Accepted-but-unassigned students if the workflow permits them.
- Optional same-company opportunity reads.
- Company-filtered Tasks query and CompanyId index.
- Student-filtered TaskSubmissions query and StudentId index, constrained appropriately to the supervisor's company/task relationships.

Only Applications uses the explicitly authorized, bounded full read. Tasks and TaskSubmissions remain scoped queries. There is no privileged fallback or Rules change if any read fails.

## Verification
Run Windows PowerShell 5.1:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File Company\\MyTrainees\\Verify-MyTrainees.ps1

Tests compile the module and necessary existing dependency sources into a temporary test assembly without editing dependencies.
All Auth/database transport in tests is fake, and all fixture output is explicitly OFFLINE.
Coverage includes accepted/unassigned workflow, confirmed assignment, duplicate applications, foreign records, missing data, recorded training details, opportunity lookup, latest submission versions, week scope, denied optional progress, role/UID/project/lifetime, search/counts/empty states, encoding and actual template/designer compatibility.

Debug/Release and ASP.NET precompilation passed after the implementation.
The previous live session authenticated and loaded "jafar's solutions"; this does not establish company_test_001 / Orange Jordan ownership.
A fresh authenticated runtime result for the enhanced directory is recorded separately after user Login; offline tests are not live Firebase evidence.


## Current small-test read change
The previous authenticated runtime attempt reached the Applications CompanyId index error. The user subsequently authorized replacing only that query with a bounded authenticated full collection read and private server-side filtering.
Identity, ownership, Accepted/Confirmed distinction, deduplication and task progress logic are retained.
Existing Firebase Rules remain authoritative: the code stops on a denied full read rather than retry with public/admin access.
284 offline assertions passed, including foreign-company filtering before Student requests, known/unknown-length payload limits, record limits, malformed data and read denial.
Debug and Release builds passed. A new authenticated runtime result is recorded below when available.


## Latest runtime attempt
After rebuilding the bounded Applications implementation, the application required a new team Login.
The visible Login attempt returned "Invalid email address or password." The enhanced Applications read has therefore NOT been verified live in this run; no trainee-list appearance is claimed.
Applications no longer requests orderBy/equalTo, so its prior CompanyId-index dependency is removed by code and covered by offline request assertions.
Tasks still uses CompanyId and TaskSubmissions still uses StudentId scoped queries. Whether either needs an index in the deployed database remains unverified until a valid authorized session reaches progress loading.
No authentication change, credential extraction, public request, Firebase write or Rules change was attempted.
