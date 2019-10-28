Install-Module -Name ClipboardText -Force

Push-Location "$env:USERPROFILE\source\repos\"

function Export-FromSandbox([string] $Path) {
  $Content = Get-Content -Encoding Byte -Path $Path
  [System.Convert]::ToBase64String($Content) | Set-ClipboardText;
}

function Export-Sample([string] $Path){
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