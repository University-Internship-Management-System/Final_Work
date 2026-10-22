# Local My Trainees fixture preview

This standalone command-line tool is not a test login, Firebase account, Web Forms route or authentication bypass. The existing login page contains a Company Supervisor demo button, but repository inspection did not establish that its account exists or is authorized in Firebase. No passwords or tokens are read, printed or stored by this tool.

## Run

1. Build the existing solution in **Debug** in Visual Studio. This launcher deliberately refuses the currently built Release application. No shared configuration or role/session changes are needed.
2. Open PowerShell in the web application folder (the folder containing Web.config).
3. If Node is on PATH:

```powershell
node .\Company\MyTrainees\Preview-MyTrainees.cjs --local-development-only
```

With this machine's bundled Node runtime:

```powershell
& "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" .\Company\MyTrainees\Preview-MyTrainees.cjs --local-development-only
```

4. Open **http://127.0.0.1:60111/**. Stop with Ctrl+C. Optional `--port 60112` selects another local port.

No password is required or provided. supervisor.test@example.com is a label for a dummy view model, not a registered account or signed-in identity.

## Coverage and limits

Three fictitious confirmed trainees and one accepted-only fixture use reserved example.com addresses. The accepted fixture is excluded from the list and count. Search by name/major, invalid/no-match input, counts, safe text rendering and responsive cards can be inspected. The real ASPX ItemTemplate and existing CSS are reused. Loading/search in this preview are client-side simulations, not the Web Forms server lifecycle. Shared navigation, authorization, academic progress and approved hours are not simulated.

The server accepts only loopback GET / requests with an exact localhost host, rejects cross-origin requests, sends no-store responses and prohibits client network requests with CSP. It does not load credentials, contact Firebase, create records or set MyTrainees.ReadApproval. It is not registered in the .csproj, referenced from ASPX, or included in normal Debug/Release deployment. It refuses IIS/production environments and refuses to start when the built application has Release optimization metadata. Self-tests only exercise pure offline rendering and never start a server; they can run without a Debug assembly.

```powershell
node .\Company\MyTrainees\Preview-MyTrainees.cjs --local-development-only --self-test
```

A real authorized Company Supervisor account, verified UID ownership mapping, deployed read permissions/indexes and explicit approved query/confirmation/disclosure contracts are still required for the real MyTrainees.aspx page. A preview success does not prove login, company isolation in deployed Rules or live Firebase access. Do not add this utility to Content/Compile registrations or deploy development utilities manually.