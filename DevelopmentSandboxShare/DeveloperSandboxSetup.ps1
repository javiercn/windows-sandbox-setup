Set-ExecutionPolicy Bypass -Scope Process -Force;

$visualStudioSetup = @'
<#
.SYNOPSIS
    Installs or updates Visual Studio on a local developer machine.
.DESCRIPTION
    This installs Visual Studio along with all the workloads required to contribute to this repository.
.PARAMETER Edition
    Selects which 'offering' of Visual Studio to install. Must be one of these values:
        BuildTools
        Community
        Professional
        Enterprise (the default)
.PARAMETER Channel
    Selects which channel of Visual Studio to install. Must be one of these values:
        Release (the default)
        Preview
.PARAMETER InstallPath
    The location on disk where Visual Studio should be installed or updated. Default path is location of latest
    existing installation of the specified edition, if any. If that VS edition is not currently installed, default
    path is '${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\`$Edition".
.PARAMETER Passive
    Run the installer without requiring interaction.
.PARAMETER Quiet
    Run the installer without UI and wait for installation to complete.
.LINK
    https://visualstudio.com
    https://github.com/aspnet/AspNetCore/blob/master/docs/BuildFromSource.md
.EXAMPLE
    To install VS 2019 Enterprise, run this command in PowerShell:

        .\InstallVisualStudio.ps1
#>
param(
    [ValidateSet('BuildTools','Community', 'Professional', 'Enterprise')]
    [string]$Edition = 'Enterprise',
    [ValidateSet('Release', 'Preview')]
    [string]$Channel = 'Release',
    [string]$InstallPath,
    [switch]$Passive,
    [switch]$Quiet
)

if ($env:TF_BUILD) {
    Write-Error 'This script is not intended for use on CI. It is only meant to be used to install a local developer environment. If you need to change Visual Studio requirements in CI agents, contact the @aspnet/build team.'
    exit 1
}

if ($Passive -and $Quiet) {
    Write-Host -ForegroundColor Red "Error: The -Passive and -Quiet options cannot be used together."
    Write-Host -ForegroundColor Red "Run ``Get-Help $PSCommandPath`` for more details."
    exit 1
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 1

$intermedateDir = "$PSScriptRoot"
mkdir $intermedateDir -ErrorAction Ignore | Out-Null

$bootstrapper = "$intermedateDir\vsinstaller.exe"
$ProgressPreference = 'SilentlyContinue' # Workaround PowerShell/PowerShell#2138

$channelUri = "https://aka.ms/vs/16/release"
$responseFileName = "vs"
if ("$Edition" -eq "BuildTools") {
    $responseFileName += ".buildtools"
}
if ("$Channel" -eq "Preview") {
    $responseFileName += ".preview"
    $channelUri = "https://aka.ms/vs/16/pre"
}

$responseFile = "$PSScriptRoot\$responseFileName.json"
$channelId = (Get-Content $responseFile | ConvertFrom-Json).channelId

$bootstrapperUri = "$channelUri/vs_$($Edition.ToLowerInvariant()).exe"
Write-Host "Downloading Visual Studio 2019 $Edition ($Channel) bootstrapper from $bootstrapperUri"
Invoke-WebRequest -Uri $bootstrapperUri -OutFile $bootstrapper

$productId = "Microsoft.VisualStudio.Product.$Edition"
if (-not $InstallPath) {
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere)
    {
        $installations = & $vsWhere -version '[16,17)' -format json -sort -prerelease -products $productId | ConvertFrom-Json
        foreach ($installation in $installations) {
            Write-Host "Found '$($installation.installationName)' in '$($installation.installationPath)', channel = '$($installation.channelId)'"
            if ($installation.channelId -eq $channelId) {
                $InstallPath = $installation.installationPath
                break
            }
        }
    }
}

if (-not $InstallPath) {
    if ("$Channel" -eq "Preview") {
        $InstallPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\${Edition}_Pre"
    } else {
        $InstallPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\$Edition"
    }
}

# no backslashes - this breaks the installer
$InstallPath = $InstallPath.TrimEnd('\')

[string[]] $arguments = @()
if (Test-path $InstallPath) {
    $arguments += 'modify'
}

$arguments += `
    '--productId', $productId, `
    '--installPath', "`"$InstallPath`"", `
    '--in', "`"$responseFile`"", `
    '--norestart'

if ($Passive) {
    $arguments += '--passive'
}
if ($Quiet) {
    $arguments += '--quiet', '--wait'
}

Write-Host
Write-Host "Installing Visual Studio 2019 $Edition ($Channel)" -f Magenta
Write-Host
Write-Host "Running '$bootstrapper $arguments'"

foreach ($i in 0, 1, 2) {
    if ($i -ne 0) {
        Write-Host "Retrying..."
    }

    $process = Start-Process -FilePath "$bootstrapper" -ArgumentList $arguments -ErrorAction Continue -PassThru `
        -RedirectStandardError "$intermedateDir\errors.txt" -Verbose -Wait
    Write-Host "Exit code = $($process.ExitCode)."
    if ($process.ExitCode -eq 0) {
        break
    } else {
        # https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio#error-codes
        if ($process.ExitCode -eq 3010) {
            Write-Host -ForegroundColor Red "Error: Installation requires restart to finish the VS update."
            break
        }
        elseif ($process.ExitCode -eq 5007) {
            Write-Host -ForegroundColor Red "Error: Operation was blocked - the computer does not meet the requirements."
            break
        }
        elseif (($process.ExitCode -eq 5004) -or ($process.ExitCode -eq 1602)) {
            Write-Host -ForegroundColor Red "Error: Operation was canceled."
        }
        else {
            Write-Host -ForegroundColor Red "Error: Installation failed for an unknown reason."
        }

        Write-Host
        Write-Host "Errors:"
        Get-Content "$intermedateDir\errors.txt" | Write-Warning
        Write-Host

        Get-ChildItem $env:Temp\dd_bootstrapper_*.log |Sort-Object CreationTime -Descending |Select-Object -First 1 |% {
            Write-Host "${_}:"
            Get-Content "$_"
            Write-Host
        }

        $clientLogs = Get-ChildItem $env:Temp\dd_client_*.log |Sort-Object CreationTime -Descending |Select-Object -First 1 |% {
            Write-Host "${_}:"
            Get-Content "$_"
            Write-Host
        }

        $setupLogs = Get-ChildItem $env:Temp\dd_setup_*.log |Sort-Object CreationTime -Descending |Select-Object -First 1 |% {
            Write-Host "${_}:"
            Get-Content "$_"
            Write-Host
        }
    }
}

Remove-Item "$intermedateDir\errors.txt" -errorAction SilentlyContinue
Remove-Item $intermedateDir -Recurse -Force -ErrorAction SilentlyContinue
exit $process.ExitCode
'@

$installerJson = @'
{
  "channelUri": "https://aka.ms/vs/16/pre/channel",
  "channelId": "VisualStudio.16.Preview",
  "includeRecommended": false,
  "addProductLang": [
      "en-US"
  ],
  "add": [
      "Microsoft.Net.Component.4.6.1.TargetingPack",
      "Microsoft.Net.Component.4.6.2.TargetingPack",
      "Microsoft.Net.Component.4.7.1.TargetingPack",
      "Microsoft.Net.Component.4.7.2.SDK",
      "Microsoft.Net.Component.4.7.2.TargetingPack",
      "Microsoft.Net.Component.4.7.TargetingPack",
      "Microsoft.VisualStudio.Component.Azure.Storage.Emulator",
      "Microsoft.VisualStudio.Component.VC.ATL",
      "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
      "Microsoft.VisualStudio.Component.Windows10SDK.17134",
      "Microsoft.VisualStudio.Workload.ManagedDesktop",
      "Microsoft.VisualStudio.Workload.NativeDesktop",
      "Microsoft.VisualStudio.Workload.NetCoreTools",
      "Microsoft.VisualStudio.Workload.NetWeb",
      "Microsoft.VisualStudio.Workload.VisualStudioExtension"
  ]
}
'@

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install pwsh -y
choco install msbuild-structured-log-viewer -y
choco install sysinternals -y
choco install fiddler -y
choco install ilspy -y
choco install nodejs -y
choco install dotnetcore-sdk -y
choco install googlechrome -y
choco install firefox -y
choco install microsoft-edge-insider -y
choco install vscode -y
choco install git -y
choco install sharex -y
choco install ffmpeg -y
choco install ilmerge -y

$sandboxWd = "$env:USERPROFILE\.sandbox\";
mkdir $sandboxWd;
Push-Location $sandboxWd;

if (-not (Test-Path $env:USERPROFILE\source\repos)) {
    mkdir $env:USERPROFILE\source\repos | Out-Null;
}

Out-File InstallVisualStudio.ps1 -InputObject $visualStudioSetup;
Out-File vs.preview.json -InputObject $installerJson;

.\InstallVisualStudio.ps1 -Passive -Channel Preview -Edition Professional

Pop-Location

Register-ScheduledJob -Name InitGit -ScriptBlock {
    git config --global user.name sandbox
    git config --global user.email "sandbox@example.com"
} -RunNow;

Start-Sleep -Seconds 2;
Get-Job InitGit | Wait-Job | Receive-Job;

mkdir $env:USERPROFILE\Documents\Powershell;
Copy-Item $env:USERPROFILE\Desktop\DevelopmentSandboxShare\Microsoft.PowerShell_profile.ps1 $env:USERPROFILE\Documents\Powershell\Microsoft.PowerShell_profile.ps1

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force;

Register-ScheduledJob -Name InstallDotNetNightly -ScriptBlock {
    pwsh.exe -executionpolicy bypass -f $env:USERPROFILE\Desktop\DevelopmentSandboxShare\InstallLatestNightlyDotNetAndCreateProjects.ps1 "3.1.1" # This is for 3.1.1xx on the core-sdk repo
} -RunNow;

Start-Sleep -Seconds 2;
Get-Job InstallDotNetNightly | Wait-Job | Receive-Job;

Register-ScheduledJob -Name InstallLatestReleasedPreviewDotNet -ScriptBlock {
    pwsh.exe -executionpolicy bypass -f $env:USERPROFILE\Desktop\DevelopmentSandboxShare\InstallLatestReleasedPreviewDotNetAndCreateProjects.ps1 "3.1" # This is for 3.1.1xx on the core-sdk repo
} -RunNow;

Start-Sleep -Seconds 2;
Get-Job InstallLatestReleasedPreviewDotNet | Wait-Job | Receive-Job;

Register-ScheduledJob -Name CreateProjects -ScriptBlock { Invoke-Expression $env:USERPROFILE\Desktop\DevelopmentSandboxShare\DotNetProjectCreationScripts.ps1 } -RunNow
Start-Sleep -Seconds 2;
Get-Job CreateProjects | Wait-Job | Receive-Job;

Register-ScheduledJob -Name InstallDotNetTools -ScriptBlock { Invoke-Expression $env:USERPROFILE\Desktop\DevelopmentSandboxShare\DotNetToolsInstallation.ps1 } -RunNow
Start-Sleep -Seconds 2;
Get-Job InstallDotNetTools | Wait-Job | Receive-Job;

Start-Process (Resolve-Path "$env:USERPROFILE\source\repos");

function Set-DnsHostNameAndCertificate([string]$hostName) {
    $createCertCommand = @"
`$serverCert = New-SelfSignedCertificate -DnsName "$hostName.example.com" -CertStoreLocation "cert:CurrentUser\My";
`$file = `$serverCert | Export-Certificate -FilePath "$hostName.example.com.cer";
`$file | Import-Certificate -CertStoreLocation Cert:\CurrentUser\Root\;
"@;

    $createCertCommand | Out-File generateCert.ps1;

    powershell.exe .\generateCert.ps1;

    Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1    $hostName.example.com"
    Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "::1          $hostName.example.com"
}

Set-DnsHostNameAndCertificate "client";
Set-DnsHostNameAndCertificate "server";

function Register-TrustedLocalhostCertificates() {
    Get-ChildItem Cert:\CurrentUser\My\ -DnsName 'localhost' |
    Where-Object FriendlyName -Like '*ASP.NET*' |
    Export-Certificate -FilePath (New-TemporaryFile) | Import-Certificate -CertStoreLocation Cert:\CurrentUser\Root\;

    Get-ChildItem Cert:\LocalMachine\My\ -DnsName 'localhost' |
    Where-Object FriendlyName -Like '*IIS Express*' |
    Export-Certificate -FilePath (New-TemporaryFile) | Import-Certificate -CertStoreLocation Cert:\CurrentUser\Root\;
}

Register-TrustedLocalhostCertificates

$initialText = @'
This is the developer sandbox for ASP.NET Core.
This shell is not fully initialized as the path is not correctly set, just open a new shell instance to get the path
and everything else working properly.
There is an instance of the most common project types under $env:USERPROFILE\source\repos\<<version>>.
Currently we create the projects for the latest released version and the latest nightly version.
The powershell instance comes with a built-in profile that comes with some handy functions.
You can run 'Set-VSEnvironment <<path>>' to set the powershell profile to use a given .NET Core instance. The path
is optional if you are inside a folder with a '.dotnet' subfolder containing a dotnet instance.

All projects are created and git is initialized in them so that if you make changes you can:
1. Know exactly what you have changed (useful for givin repros/guidance)
2. Revert the changes so that you can keep using the project for many investigations without fear of leaving something dirty by accident.

Currently the VM doesn't map any folder with write permissions, that's done for security reasons in case you want to run customer code in it.
If you want to export a file out of the sandbox there's a helper command you can use "Export-FromSandbox" that will Base64 encode the contents
of any file and copy them to the clipboard. Then from your host app you can use "Import-FromSandbox <<destination>> to get the file back.

If you have modified any of the projects and want to produce a zip with a repro for a customer, you can simply call Export-Sample <<path>> and
it will take care of staging the current changes, calling git clean to remove artifacts, zip the contents of the project and copy the zip to the
clipboard. From there you can simply use Import-FromSandbox to get the zip into your machine.

The definition of Import-FromSandbox is here for reference, you need to have installed and imported the ClipboardText module.
function Import-FromSandbox([string] $Path){
  $Base64 = Get-ClipboardText -Raw;
  Set-Content -Value $([System.Convert]::FromBase64String($Base64)) -AsByteStream -Path $Path
}
'@

Out-File -FilePath "$sandboxWd\README" -InputObject $initialText;

Start-Process "C:\Program Files\PowerShell\6\pwsh.exe" -ArgumentList "-noexit", "-c", "Get-Content $sandboxWd\README" -WorkingDirectory (Resolve-Path "$env:USERPROFILE\source\repos\");