if ((Get-InstalledModule | Where-Object { $_.Name -eq "ClipboardText" } | Measure-Object).Count -eq 0) {
  Install-Module ClipboardText -AllowPrerelease -Force;
}
else {
  Import-Module ClipboardText;
}

if ((Get-InstalledModule | Where-Object { $_.Name -eq "posh-git" } | Measure-Object).Count -eq 0) {
  Install-Module posh-git -AllowPrerelease -Force;
}
else {
  Import-Module posh-git;
}

Push-Location "$env:USERPROFILE\source\repos\"

function Export-FromSandbox([string] $Path) {
  $Content = Get-Content -AsByteStream -Path $Path
  [System.Convert]::ToBase64String($Content) | Set-ClipboardText;
}

function Export-Sample([string] $Path) {
  $fullPath = Resolve-Path $Path;
  Push-Location $fullPath;
  git add .;
  git clean -xdff;
  $zipName = (Get-Item .).Name;
  $zipPath = "$fullPath\$zipName.zip";
  Get-ChildItem $fullPath -Exclude .git, .gitignore | Compress-Archive -DestinationPath $zipPath;
  Export-FromSandbox $zipPath;
  Pop-Location;
}

function Set-DnsHostNameAndCertificate([string]$hostName){
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

function Set-ServerEnvironment([string]$hostName, [string]$projectName, [int]$httpPort, [int]$httpsPort){

      $launchSettingsJson = Get-Content .\Properties\launchSettings.json | ConvertFrom-Json;
      $launchSettingsJson.PSObject.Properties.Remove('iisSettings')
      $launchSettingsJson.profiles.PSObject.Properties.Remove('IIS Express')
      $applicationUrl = $launchSettingsJson.profiles."$projectName".applicationUrl;
      $applicationUrl = $applicationUrl -replace 'localhost:5000', "$hostName.example.com:$httpPort";
      $applicationUrl = $applicationUrl -replace 'localhost:5001', "$hostName.example.com:$httpsPort";
      $launchSettingsJson.profiles."$projectName".applicationUrl = $applicationUrl;
      ConvertTo-Json $launchSettingsJson -Depth 10 | Set-Content .\Properties\launchSettings.json

      $appSettingsDev = Get-Content .\appsettings.Development.json | ConvertFrom-Json;
      $kestrelCert = @"
{
  "Certificates": {
    "Default": {
      "Subject": "$hostName.example.com",
      "Store": "My",
      "Location": "CurrentUser",
      "AllowInvalid": "true"
    }
  }
}
"@;

      $appSettingsDev | Add-Member -NotePropertyName "Kestrel" -NotePropertyValue (ConvertFrom-Json $kestrelCert);
      ConvertTo-Json $appSettingsDev -Depth 10 | Set-Content .\appsettings.Development.json;
  }

function Expand-Repro (
  [Parameter(ParameterSetName = "FromZip", Mandatory = $true)]
  [string]$ZipDownloadUrl,
  [Parameter(ParameterSetName = "FromGithubRepo", Mandatory = $true)]
  [string]$CloneUrl,
  [string]$Name,
  [string]$ReproExpansionPath = ""
) {
  if ($ReproExpansionPath -eq "") {
    $ReproExpansionPath = "$env:USERPROFILE\source\repos\repros";
    if (-not (Test-path $ReproExpansionPath)) {
      mkdir $ReproExpansionPath | out-null;
    }
  }

  if ($ZipDownloadUrl -eq "") {
    if ($Name -eq "") {
      $Name = ((([Uri]$CloneUrl).LocalPath) -split '/' | Select-Object -Last 1) -replace ".git", "";
    }

    $repoPath = (Join-Path $ReproExpansionPath $Name);
    git clone $CloneUrl $repoPath;
    $targetPath = $repoPath;
  }
  else {
    if ($Name -eq "") {
      $Name = ((([Uri]$ZipDownloadUrl).LocalPath) -split '/' | Select-Object -Last 1);
      if ($Name -notlike "*.zip") {
        $Name = "$Name.zip";
      }
    }
    
    $zipPath = (Join-Path $ReproExpansionPath $Name);
    $expandedZipFolder = ($zipPath -replace ".zip", "");
    Invoke-WebRequest $ZipDownloadUrl -OutFile $zipPath;
    Expand-Archive $zipPath -DestinationPath $expandedZipFolder;
    
    $targetPath = $expandedZipFolder;
  }

  Invoke-Project $targetPath;
}

function Invoke-Project([string]$TargetPath) {
  Push-Location $TargetPath;

  $solutionFolder = Get-ChildItem -Path $TargetPath -File -Recurse -Filter *.sln | Select-Object -First 1 | Select-Object -ExpandProperty DirectoryName;
  if ($solutionFolder -ne "") {
    Push-Location $solutionFolder;
    dotnet build;
    Write-Host "Solution folder found: $solutionFolder";
  }

  $projectFolder = Get-ChildItem -Path $TargetPath -File -Recurse -Filter "*.csproj" | Select-Object -ExpandProperty DirectoryName;
  Write-Host "Projects found: $($projectFolder -join ' ')"

  if ($projectFolder.Count -eq 1) {
    Push-Location $projectFolder;
    dotnet run;
  }
  else {
    $sites = @();
    foreach ($candidate in $projectFolder) {
      $found = Resolve-WebSite $candidate;
      if ($null -ne $found) {
        $sites += $found;
      }
    }

    Write-Host "Sites found: $($sites -join ' ')"

    if ($sites.Count -gt 1) {
      Write-Host "Multiple sites to run";
    }
    else {
      $sites | Push-Location;
      Invoke-WebSite (resolve-path .\*csproj).Path;
    }
  }
}

function Invoke-WebSite ([string]$site) {
  $tmp = New-TemporaryFile;
  Start-Process dotnet -ArgumentList "run", "--project", $site -RedirectStandardOutput $tmp -NoNewWindow;
  Get-Content $tmp -Wait | ForEach-Object {
    if($_ -match "Now listening on: (http://localhost:\d+)"){
      Start-Process $Matches[1];
    }
    if($_ -match "Application is shutting down..."){
      break;
    }
    $_
  }
}

function Resolve-WebSite([string]$candidate) {
  Write-Host "Examining project folder $candidate";
  $projectFile = Get-ChildItem $candidate -Filter "*.csproj" -File;
  if ($projectFile.Count -ne 1) {
    Write-Host "An unexpected number of project files found '$($projectFile.Count)'";
    Write-Host $projectFile;
    return $null;
  }
  else {
    Write-Host "Examining project file $projectFile"
  }
  $projectContents = ([xml](Get-Content $projectFile));
  Write-Host "Project $projectFile contents:"
  Get-Content $projectFile | Out-Host;

  $sdk = $projectContents | Select-Xml "/Project/@Sdk" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty Value;
  Write-Host "Found SDK $sdk";

  $targetFramework = $projectContents | Select-Xml "//TargetFramework/text()" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty Value;
  Write-Host "Found target framework $targetFramework";
  if (($sdk -ieq "Microsoft.NET.Sdk.Web") -and ($targetFramework -like "netcoreapp*")) {
    return $candidate;
  }
  else {
    return $null;
  }
}

function Set-VSEnvironment($BasePath = $null) {
  if ($null -ne $basePath) {
    $x64DotNetFolder = $basePath;
  }
  else {
    $x64DotNetFolder = "$PWD/.dotnet/x64";
  }
  $x64DotNet = Test-Path "$x64DotNetFolder/dotnet.exe";
  if ($x64DotNet) {
    $x64DotNetFolder = Resolve-Path $x64DotNetFolder
  }
  elseif ($null -ne $basePath) {
    Write-Error("Invalid base path '$basePath'.");
    return;
  }

  $x86DotNetFolder = "$PWD/.dotnet"
  $x86DotNet = Test-Path "$x86DotNetFolder/dotnet.exe";
  if ($x86DotNet) {
    $x86DotNetFolder = Resolve-Path "$PWD/.dotnet"
  }

  if (-not ($x64DotNet -or $x86DotNet)) {
    throw "No dotnet.exe found in '$x64DotNetFolder/dotnet.exe'";
  }

  if ($x64DotNet) {
    $dotNetFolder = $x64DotNetFolder;
  }
  else {
    $dotNetFolder = $x86DotNetFolder;
  }
  $env:DOTNET_ROOT = $dotNetFolder;
  $env:DOTNET_MULTILEVEL_LOOKUP = 0;
  if (-not ($env:Path.StartsWith($dotNetFolder))) {
    $env:Path = "$dotNetFolder;$env:Path";
  }
  Get-VSEnvironment;
}

function Get-VSEnvironment() {
  Write-Output "VS Environment";
  Write-Output ('$env:DOTNET_ROOT: ' + $env:DOTNET_ROOT);
  Write-Output ('$env:DOTNET_MULTILEVEL_LOOKUP: ' + $env:DOTNET_MULTILEVEL_LOOKUP);
  Write-Output ('$env:Path: ' + ($env:Path.Split(';') | Where-Object { $_ -like "*dotnet*" } | Select-Object -First 1));
}