@echo off
rem UIMS - checks the project on this computer, fixes what it can, and writes fix-result.txt
rem Double-click this file. Close Visual Studio first.
set "UIMS_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:UIMS_SELF); $i=$s.IndexOf('#PS'+'-START'); Invoke-Expression $s.Substring($i)"
exit /b
#PS-START
$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $env:UIMS_SELF
$Log = $Root + '\fix-result.txt'
$BuildOut = $env:TEMP + '\uims_build.txt'
Set-Content -Path $Log -Value ('===== UIMS fix-project   ' + (Get-Date) + '   ' + $env:COMPUTERNAME + ' =====')
$Fixes = New-Object System.Collections.ArrayList
$Problems = New-Object System.Collections.ArrayList
$Warnings = New-Object System.Collections.ArrayList
$Dll = 'Microsoft.CodeDom.Providers.DotNetCompilerPlatform'
$SlnName = 'the solution file (.sln)'

function Log($m) { Add-Content -Path $Log -Value $m }
function Say($m, $c) { if ($c) { Write-Host $m -ForegroundColor $c } else { Write-Host $m }; Log $m }
function Step($n, $m) { Write-Host ''; Write-Host ('[' + $n + '/9] ' + $m) -ForegroundColor Cyan; Log ''; Log ('--- ' + $m) }
function Ok($m) { Say ('  ok: ' + $m) 'Green' }
function Fixed($m) { [void]$Fixes.Add($m); Say ('  FIXED: ' + $m) 'Yellow' }
function Warn($m) { [void]$Warnings.Add($m); Say ('  WARNING: ' + $m) 'Yellow' }
function Problem($m) { [void]$Problems.Add($m); Say ('  PROBLEM: ' + $m) 'Red' }
function WaitKey() { if (-not $env:UIMS_NO_OPEN) { Write-Host ''; Write-Host 'Press Enter to close this window...'; [void][Console]::ReadLine() } }

function Summary() {
    Log ''
    Log '===== SUMMARY ====='
    if ($Fixes.Count -gt 0) { Say ''; Say 'Fixed automatically:' 'Yellow'; foreach ($f in $Fixes) { Say ('  - ' + $f) } }
    if ($Warnings.Count -gt 0) { Say ''; Say 'Warnings:' 'Yellow'; foreach ($w in $Warnings) { Say ('  - ' + $w) } }
    Say ''
    if ($Problems.Count -eq 0) {
        Say ('RESULT: everything is fine. Open ' + $SlnName + ' in Visual Studio and run the site. (Use Start or Build, not Rebuild or Clean.)') 'Green'
    } else {
        Say 'RESULT: these problems could not be fixed automatically:' 'Red'
        foreach ($p in $Problems) { Say ('  - ' + $p) 'Red' }
        try { Get-Content -Path $Log -Raw | Set-Clipboard; Say ''; Say 'The full report was copied to your clipboard. Paste it in a message to Wadea.' } catch { Say ''; Say 'Please send the file fix-result.txt (next to this script) to Wadea.' }
    }
    Say ('Report file: ' + $Log)
}
function Stop-Now($m) { Problem $m; Summary; if (-not $env:UIMS_NO_OPEN) { Start-Process notepad $Log }; WaitKey; exit }

function Ver3($v) { if (-not $v) { return '' } $p = $v -split '\.'; return (($p | Select-Object -First 3) -join '.') }
function ReadVersions($proj) {
    $web = [regex]::Match((Get-Content ($proj + '\Web.config') -Raw), 'DotNetCompilerPlatform\.CSharpCodeProvider[^"]*Version=([\d.]+)').Groups[1].Value
    $pkg = [regex]::Match((Get-Content ($proj + '\packages.config') -Raw), 'id="Microsoft\.CodeDom\.Providers\.DotNetCompilerPlatform"\s+version="([\d.]+)"').Groups[1].Value
    $prj = [regex]::Match((Get-Content ($proj + '\UniversityInternshipManagmentSystem.csproj') -Raw), 'DotNetCompilerPlatform\.(\d+\.\d+\.\d+)\\lib').Groups[1].Value
    return @{ Web = (Ver3 $web); Pkg = (Ver3 $pkg); Csproj = (Ver3 $prj) }
}
function RunBuild($msbuildPath, $slnPath) { & $msbuildPath $slnPath -restore -p:RestorePackagesConfig=true -t:Build -v:m -nologo *> $BuildOut; return $LASTEXITCODE }
function Agree($v) { return ((@($v.Web, $v.Pkg, $v.Csproj) | Where-Object { $_ } | Select-Object -Unique).Count -le 1) }
function AdviceFor($text) {
    $a = @()
    if ($text -match 'NU1301|NU1101|NU1102|NU1100|service index|missing on this computer') { $a += 'NuGet could not download the packages: connect to the internet (turn off a VPN or proxy if you use one) and run this file again.' }
    if ($text -match 'MSB4019|MSB4226|WebApplication\.targets') { $a += 'Visual Studio is missing the web tools: open Visual Studio Installer, click Modify, tick "ASP.NET and web development", install, then run this file again.' }
    if ($text -match 'MSB3644|targeting pack') { $a += 'The .NET Framework 4.8 targeting pack is missing: Visual Studio Installer, Modify, Individual components, tick ".NET Framework 4.8 targeting pack", install, then run this file again.' }
    if ($text -match 'CS0246|CS0234|CS0103|CS0012') { $a += 'The code uses a class or file that is not in your project yet. Run "git pull origin dev" and run this file again. If it still fails, tell Wadea the file name from the error.' }
    if ($text -match 'CS2001|MSB3202') { $a += 'A file listed in the project is missing on disk. Run "git pull origin dev", then run this file again.' }
    if ($text -match 'MSB3021|MSB3026|MSB3027|being used by another process|Access to the path') { $a += 'A file is locked. Close Visual Studio and IIS Express and any program using the folder (or pause the antivirus), then run this file again.' }
    if ($text -match 'CS8300|CS8803|CS1056|merge conflict marker') { $a += 'A file still has an unfinished git merge conflict (lines with <<<<<<<, ======= and >>>>>>>). Open that file, keep the correct code, delete those marker lines, save, then run this file again.' }
    return ($a | Select-Object -Unique)
}

function Main {
    # ---------------------------------------------------------------- 1
    Step 1 'Checking Visual Studio and the web server'
    if ((Get-Process devenv -ErrorAction SilentlyContinue) -and (-not $env:UIMS_NO_OPEN)) {
        Write-Host 'Visual Studio is open. Please close it, then run this file again.' -ForegroundColor Red
        [void][Console]::ReadLine(); exit
    }
    Ok 'Visual Studio is closed'
    if (Get-Process iisexpress -ErrorAction SilentlyContinue) { Get-Process iisexpress -ErrorAction SilentlyContinue | Stop-Process -Force; Fixed 'stopped the old IIS Express web server' } else { Ok 'no old web server running' }

    # ---------------------------------------------------------------- 2
    Step 2 'Finding the project'
    $csprojFile = Get-ChildItem -Path $Root -Recurse -Filter 'UniversityInternshipManagmentSystem.csproj' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\(packages|bin|obj)\\' } | Select-Object -First 1
    if (-not $csprojFile) { Stop-Now 'The project file was not found. Put this file inside the repository folder and run it again.' }
    $Proj = $csprojFile.DirectoryName
    $Outer = Split-Path -Parent $Proj
    Ok ('project: ' + $Proj)
    if ($Proj.Length -gt 140) { Warn 'The folder path is very long. Windows can fail on paths over 260 characters. Move the repository closer to the drive root, for example C:\UIMS' }
    if ($Proj -match 'OneDrive') { Warn 'The repository is inside OneDrive. OneDrive can lock or remove build files. Move it out of OneDrive, for example to C:\UIMS' }
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        Push-Location $Proj
        Log ('git branch: ' + ((& git branch --show-current 2>&1) | Out-String).Trim())
        Log ('git commit: ' + ((& git log -1 --format='%h %s' 2>&1) | Out-String).Trim())
        Pop-Location
    } else { Warn 'git is not installed or not on the PATH, so some checks are skipped.' }

    # ---------------------------------------------------------------- 3
    Step 3 'Looking for unfinished merge conflicts'
    $hits = Get-ChildItem -Path $Proj -Recurse -File -Include *.cs,*.aspx,*.ascx,*.master,*.config,*.csproj,*.js,*.css,*.json -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\(packages|bin|obj|node_modules)\\' } |
        Select-String -Pattern '^(<<<<<<< |>>>>>>> )' -List -ErrorAction SilentlyContinue
    if ($hits) { foreach ($h in $hits) { Problem ('Unfinished merge conflict (lines starting with <<<<<<< or >>>>>>>) in: ' + $h.Path) } } else { Ok 'no conflict markers found' }

    # the files listed in the .csproj must match the files in the folder (a very common team problem)
    $csTxt = [IO.File]::ReadAllText($Proj + '\UniversityInternshipManagmentSystem.csproj')
    $listed = @{}
    foreach ($mm in [regex]::Matches($csTxt, '<(Compile|Content|EmbeddedResource)\s+Include="([^"]+)"')) { $pp = $mm.Groups[2].Value; if ($pp -notmatch '[\*\$]') { $listed[$pp.ToLower()] = $pp } }
    $gone = @($listed.Keys | Where-Object { -not (Test-Path -LiteralPath ($Proj + '\' + $_)) })
    foreach ($g in ($gone | Select-Object -First 15)) { Problem ('The project file lists ' + $listed[$g] + ' but that file is not on your computer. Run "git pull origin dev". If it is still missing, the teammate who added it forgot to commit it.') }
    $disk = Get-ChildItem -Path $Proj -Recurse -File -Include *.aspx,*.ascx,*.master,*.cs,*.ashx,*.asmx -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\(bin|obj|packages|\.vs)\\' }
    $extra = @($disk | ForEach-Object { $_.FullName.Substring($Proj.Length + 1) } | Where-Object { -not $listed.ContainsKey($_.ToLower()) })
    foreach ($x in ($extra | Select-Object -First 15)) { Warn ($x + ' is in the folder but not in the project file, so Visual Studio ignores it. In Solution Explorer click "Show All Files", right-click it, choose "Include In Project", then commit the .csproj.') }
    if ($gone.Count -eq 0 -and $extra.Count -eq 0) { Ok 'every file listed in the project exists, and no page is left out of the project' }

    # ---------------------------------------------------------------- 4
    Step 4 'Checking that the package versions agree'
    $v = ReadVersions $Proj
    Log ('CodeDom version  Web.config=' + $v.Web + '  packages.config=' + $v.Pkg + '  csproj=' + $v.Csproj)
    if (-not (Agree $v)) {
        Warn ('Web.config (' + $v.Web + '), packages.config (' + $v.Pkg + ') and the project file (' + $v.Csproj + ') use different versions of the CodeDom package.')
        if ($git) {
            Push-Location $Proj
            $o = (& git stash push -m 'uims-fix backup' -- Web.config UniversityInternshipManagmentSystem.csproj packages.config 2>&1) | Out-String
            Pop-Location
            Log $o.Trim()
            $v = ReadVersions $Proj
            if (Agree $v) { Fixed ('put the 3 package files back to the team version ' + $v.Pkg + ' (your old versions are saved in a git stash named "uims-fix backup")') }
            else { Problem 'The package versions still disagree after restoring the files. Ask Wadea to check the branch.' }
        } else { Problem 'The package versions disagree and git is not available to restore the files.' }
    } elseif (-not $v.Csproj) { Warn 'The project file has no reference to the CodeDom package folder, so the build may not copy the dll into bin. This script copies it by hand if needed.' }
    else { Ok ('all three files use version ' + $v.Pkg) }

    # ---------------------------------------------------------------- 5
    Step 5 'Checking the tools on this computer'
    $vsw = ${env:ProgramFiles(x86)} + '\Microsoft Visual Studio\Installer\vswhere.exe'
    $msb = $null
    $vsPath = $null
    if (Test-Path $vsw) {
        $msb = (& $vsw -latest -prerelease -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1)
        $vsPath = (& $vsw -latest -prerelease -property installationPath | Select-Object -First 1)
        $vsVer = (& $vsw -latest -prerelease -property installationVersion | Select-Object -First 1)
    }
    if (-not $msb) { $c = Get-Command msbuild -ErrorAction SilentlyContinue; if ($c) { $msb = $c.Source } }
    if (-not $msb) { Stop-Now 'MSBuild was not found. Install Visual Studio with the "ASP.NET and web development" workload.' }
    Ok ('MSBuild: ' + $msb)
    if ($vsPath) {
        $webTargets = Get-ChildItem -Path ($vsPath + '\MSBuild\Microsoft\VisualStudio') -Recurse -Filter 'Microsoft.WebApplication.targets' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($webTargets) { Ok 'the ASP.NET web tools are installed' } else { Problem 'The "ASP.NET and web development" workload is not installed. Open Visual Studio Installer, click Modify, tick it and install.' }
    }
    if (Test-Path (${env:ProgramFiles(x86)} + '\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8')) { Ok '.NET Framework 4.8 targeting pack is installed' } else { Problem 'The .NET Framework 4.8 targeting pack is missing. Visual Studio Installer, Modify, Individual components, tick ".NET Framework 4.8 targeting pack".' }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        [void](Invoke-WebRequest 'https://api.nuget.org/v3/index.json' -UseBasicParsing -TimeoutSec 15)
        Ok 'nuget.org is reachable'
    } catch { Warn 'Cannot reach nuget.org (no internet, VPN, proxy or firewall). The packages cannot be downloaded unless they are already on this computer.' }
    $sln = Get-ChildItem -Path $Outer -Filter '*.sln' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $sln) { $sln = Get-ChildItem -Path $Outer -Filter '*.slnx' -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $sln) { Stop-Now 'No solution file (.sln) was found next to the project folder.' }
    Ok ('solution: ' + $sln.FullName)
    $global:SlnName = $sln.Name
    if ($sln.Extension -eq '.slnx' -and $vsVer -and ([version]$vsVer) -lt ([version]'17.10')) { Warn ('The solution is a .slnx file, which needs Visual Studio 2022 version 17.10 or newer. Yours is ' + $vsVer + '. Update Visual Studio.') }
    $iis = @((${env:ProgramFiles} + '\IIS Express\iisexpress.exe'), (${env:ProgramFiles(x86)} + '\IIS Express\iisexpress.exe')) | Where-Object { Test-Path $_ }
    if ($iis) { Ok 'IIS Express is installed' } else { Problem 'IIS Express is not installed. It comes with the "ASP.NET and web development" workload in Visual Studio Installer.' }
    $port = [regex]::Match($csTxt, '<IISUrl>http://localhost:(\d+)').Groups[1].Value
    if ($port) {
        $busy = Get-NetTCPConnection -LocalPort ([int]$port) -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($busy) { $pn = (Get-Process -Id $busy.OwningProcess -ErrorAction SilentlyContinue).ProcessName; Warn ('Port ' + $port + ' (the port of this site) is already used by "' + $pn + '". Close that program, or the site will not start.') } else { Ok ('port ' + $port + ' is free') }
    }
    $freeGb = [math]::Round((Get-Item $Proj).PSDrive.Free / 1GB, 1)
    if ($freeGb -lt 2) { Warn ('Only ' + $freeGb + ' GB free on this drive. The build may fail. Free some space.') } else { Ok ($freeGb.ToString() + ' GB free on the drive') }

    # ---------------------------------------------------------------- 6
    Step 6 'Cleaning old build files'
    foreach ($d in @(($Outer + '\packages'), ($Proj + '\bin'), ($Proj + '\obj'))) {
        if (Test-Path $d) {
            Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue
            if (Test-Path $d) { Problem ('Could not delete ' + $d + '. Something is using it: close other programs and run again.') } else { Ok ('deleted ' + $d) }
        }
    }
    foreach ($d in @(($Outer + '\.vs'), ((Split-Path -Parent $Outer) + '\.vs'))) {
        if (Test-Path $d) { Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue; Ok ('deleted the old Visual Studio cache ' + $d + ' (it is recreated automatically; it can hold a wrong IIS Express path)') }
    }
    $aspTemp = $env:LOCALAPPDATA + '\Temp\Temporary ASP.NET Files'
    if (Test-Path $aspTemp) { Remove-Item -Recurse -Force $aspTemp -ErrorAction SilentlyContinue; Ok 'cleared the old compiled ASP.NET pages (Temporary ASP.NET Files)' }
    Get-ChildItem -Path $Outer -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
    Ok 'removed the Windows "downloaded from internet" block from the files'

    # ---------------------------------------------------------------- 7
    Step 7 'Downloading packages and building (1-3 minutes)'
    $code = RunBuild $msb $sln.FullName
    if (-not (Get-ChildItem -Path ($Outer + '\packages') -Directory -Filter ($Dll + '.*') -ErrorAction SilentlyContinue)) {
        Warn 'The packages were not downloaded. Clearing the NuGet download cache and trying once more...'
        Remove-Item -Recurse -Force ($env:LOCALAPPDATA + '\NuGet\v3-cache') -ErrorAction SilentlyContinue
        $code = RunBuild $msb $sln.FullName
    }
    Log ('MSBuild exit code: ' + $code)
    $lines = @(Get-Content -Path $BuildOut -ErrorAction SilentlyContinue)
    $errs = @($lines | Where-Object { $_ -match '\berror\b\s*[A-Za-z]*\d+\s*:' -or $_ -match ': error ' } | ForEach-Object { $_.Trim() } | Select-Object -Unique)
    if ($code -ne 0 -or $errs.Count -gt 0) {
        Problem ('The build reported ' + $errs.Count + ' error(s).')
        foreach ($e in ($errs | Select-Object -First 10)) { Say ('    ' + $e) }
        foreach ($a in (AdviceFor ($errs -join "`n"))) { Say ('    HOW TO FIX: ' + $a) 'Yellow' }
    } else { Ok 'the build finished without errors' }

    # ---------------------------------------------------------------- 8
    Step 8 'Checking the files in bin and repairing what is missing'
    $bin = $Proj + '\bin'
    $pkgDir = Get-ChildItem -Path ($Outer + '\packages') -Directory -Filter ($Dll + '.*') -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not (Test-Path ($bin + '\' + $Dll + '.dll'))) {
        if ($pkgDir -and (Test-Path ($pkgDir.FullName + '\lib\net45'))) {
            New-Item -ItemType Directory -Force -Path $bin | Out-Null
            Copy-Item -Path ($pkgDir.FullName + '\lib\net45\' + $Dll + '.*') -Destination $bin -Force
            Fixed 'the build did not copy the CodeDom dll into bin, so it was copied from the packages folder'
        } else { Problem 'The CodeDom package is not in the packages folder, so its dll cannot be copied. Check the internet connection.' }
    } else { Ok 'CodeDom dll is in bin' }
    if (-not (Test-Path ($bin + '\roslyn\csc.exe'))) {
        if ($pkgDir -and (Test-Path ($pkgDir.FullName + '\tools\RoslynLatest'))) {
            New-Item -ItemType Directory -Force -Path ($bin + '\roslyn') | Out-Null
            Copy-Item -Path ($pkgDir.FullName + '\tools\RoslynLatest\*') -Destination ($bin + '\roslyn') -Recurse -Force
            Fixed 'the roslyn compiler files were missing from bin\roslyn, so they were copied from the packages folder'
        } else { Problem 'bin\roslyn\csc.exe is missing and could not be repaired.' }
    } else { Ok 'roslyn compiler files are in bin' }
    foreach ($f in @('UniversityInternshipManagmentSystem.dll', 'Newtonsoft.Json.dll')) {
        if (Test-Path ($bin + '\' + $f)) { Ok ($f + ' is in bin') } else { Problem ($f + ' is missing from bin (the build did not produce it).') }
    }
    if (Test-Path ($bin + '\' + $Dll + '.dll')) {
        $dv = ([Reflection.AssemblyName]::GetAssemblyName($bin + '\' + $Dll + '.dll')).Version.ToString()
        $v = ReadVersions $Proj
        Log ('dll version in bin = ' + $dv + ', Web.config wants = ' + $v.Web)
        if ((Ver3 $dv) -eq $v.Web) { Ok ('the CodeDom dll version (' + $dv + ') matches Web.config') } else { Problem ('The CodeDom dll in bin is version ' + $dv + ' but Web.config wants ' + $v.Web + '.') }
    }
    $cfg = Get-Content ($Proj + '\Web.config') -Raw
    foreach ($k in @('ApiKey', 'DbUrl')) {
        $m = [regex]::Match($cfg, 'key="' + $k + '"\s+value="([^"]*)"')
        if ($m.Success -and $m.Groups[1].Value.Trim().Length -gt 0) { Ok ('Web.config has a value for ' + $k) } else { Problem ('Web.config has no value for ' + $k + ', so the site cannot reach Firebase.') }
    }

    $dbUrl = [regex]::Match($cfg, 'key="DbUrl"\s+value="([^"]*)"').Groups[1].Value.Trim().TrimEnd('/')
    if ($dbUrl) {
        try { [void](Invoke-WebRequest ($dbUrl + '/.json?shallow=true') -UseBasicParsing -TimeoutSec 15); Ok 'the Firebase database answers' }
        catch {
            $sc = 0
            if ($_.Exception.Response) { $sc = [int]$_.Exception.Response.StatusCode }
            if ($sc -eq 401 -or $sc -eq 403) { Warn 'Firebase refused the request (permission denied). The site will show no data. Ask Wadea to check the database rules.' }
            else { Warn ('Cannot reach the Firebase database (' + $dbUrl + '). Check the internet connection, VPN or firewall: the site will show no data.') }
        }
    }

    # ---------------------------------------------------------------- 9
    Step 9 'Checking that nothing removes the files (antivirus)'
    Start-Sleep -Seconds 5
    if (Test-Path ($bin + '\' + $Dll + '.dll')) { Ok 'the CodeDom dll is still in bin after 5 seconds' } else { Problem 'The CodeDom dll DISAPPEARED from bin after 5 seconds. Something (antivirus?) is removing it. Add the repository folder to the Windows Security exclusions, then run this file again.' }
    $det = @(Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 5)
    if ($det.Count -gt 0) {
        Log 'Recent Windows Defender detections:'
        foreach ($d in $det) { Log ('  ' + $d.InitialDetectionTime + '  ' + (($d.Resources) -join ';')) }
        if (($det | Where-Object { (($_.Resources) -join ';') -match 'CodeDom|UniversityInternship' })) { Problem 'Windows Defender detected one of the project files. Add the repository folder to the Windows Security exclusions.' }
    }

    Log ''
    Log '--- extra details'
    Log 'bin folder:'
    Get-ChildItem -Path $bin -Name -ErrorAction SilentlyContinue | ForEach-Object { Log ('  ' + $_) }
    Log 'last 30 lines of the build output:'
    $lines | Select-Object -Last 30 | ForEach-Object { Log ('  ' + $_) }
}

try { Main } catch { Problem ('Unexpected error in the script: ' + $_.Exception.Message + ' at line ' + $_.InvocationInfo.ScriptLineNumber) }
Summary
if (-not $env:UIMS_NO_OPEN) { Start-Process notepad $Log }
WaitKey
