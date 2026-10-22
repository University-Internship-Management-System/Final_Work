param(
    [string]$FirebaseWebApiKey,
    [ValidateRange(44300,44399)][int]$HttpsPort = 44379
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$template = 'C:\Program Files\IIS Express\config\templates\PersonalWebServer\applicationhost.config'
if (!(Test-Path -LiteralPath (Join-Path $projectRoot 'bin/UniversityInternshipManagmentSystem.dll'))) { throw 'Build the Debug solution before starting the local test.' }
if ([string]::IsNullOrWhiteSpace($FirebaseWebApiKey)) { $FirebaseWebApiKey = Read-Host 'uims-student-2026 Firebase Web API Key (not the password)' }
$previous = $env:UIMS_STUDENT_FIREBASE_API_KEY
$configPath = Join-Path ([IO.Path]::GetTempPath()) ('uims-student-' + [Guid]::NewGuid().ToString('N') + '.config')
try {
    $env:UIMS_STUDENT_FIREBASE_API_KEY = $FirebaseWebApiKey
    [xml]$config = Get-Content -LiteralPath $template
    $site = $config.configuration.'system.applicationHost'.sites.site
    $site.name = 'StudentLocalTest'
    $site.application.SetAttribute('applicationPool', 'Clr4IntegratedAppPool')
    $site.application.virtualDirectory.physicalPath = $projectRoot
    $site.bindings.binding.protocol = 'https'
    $site.bindings.binding.bindingInformation = ":${HttpsPort}:localhost"
    $config.Save($configPath)
    Write-Output "Student Profile: https://localhost:$HttpsPort/Student/StudentProfilePage/Profile"
    Write-Output 'Enter the test password only in the HTTPS form. No database writes are enabled. Stop with Q or Ctrl+C.'
    & 'C:\Program Files\IIS Express\iisexpress.exe' "/config:$configPath" /site:StudentLocalTest /systray:false
}
finally {
    $env:UIMS_STUDENT_FIREBASE_API_KEY = $previous
    if (Test-Path -LiteralPath $configPath) { Remove-Item -LiteralPath $configPath }
}
