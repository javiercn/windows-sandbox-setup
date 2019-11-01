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
  
  Write-Output "Zip download url: $ZipDownloadUrl";
  Write-Output "Clone url $CloneUrl";
  Write-Output "Name $Name";
  Write-Output "Repro expansion path $ReproExpansionPath";
}

function Invoke-Project([string]$TargetPath) {
  Push-Location $TargetPath;

  $solutionFolder = Get-ChildItem -Path $TargetPath -File -Recurse -Filter *.sln | Select-Object -First 1 | Select-Object -ExpandProperty DirectoryName;
  if ($solutionFolder -ne "") {
    Push-Location $solutionFolder;
    dotnet build;            
  }

  $projectFolder = Get-ChildItem -Path $TargetPath -File -Recurse -Filter *.csproj | Select-Object -ExpandProperty DirectoryName;
  if ($projectFolder.Count -eq 1) {
    Push-Location $projectFolder;
    dotnet run;
  }
  else {
    $sites = $projectFolder | Where-Object { 
      $projectContents = ([xml](Get-ChildItem $_ -Filter *.csproj -File | Select-Object -First 1 | Get-Content));
      $sdk = $projectContents | Select-Xml "/Project/@sdk" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty Value;
      $targetFramework = $projectContents | Select-Xml "//TargetFramework/text()" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty Value;
      return $sdk -eq "Microsoft.NET.SDK" -and $targetFramework -like "netcoreapp*"
    };

    if ($sites.Count -gt 1) {
      Write-Output "Multiple sites to run";
    }
    else {
      Push-Location ($sites | Select-Object -First 1);
      dotnet run;
    }
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