param(
  [string] $DotNetVersion
)

$latestVersion = Invoke-WebRequest "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/$DotNetVersion/releases.json" | ConvertFrom-Json | Select-Object -ExpandProperty 'latest-sdk';

$BlazorWasmVersion = (Invoke-WebRequest "https://api.nuget.org/v3/registration3-gz-semver2/microsoft.aspnetcore.blazor.templates/index.json" | ConvertFrom-Json).items.upper;

C:\Users\WDAGUtilityAccount\Desktop\DevelopmentSandboxShare\dotnet-install.ps1 -version $latestVersion -InstallDir "$env:USERPROFILE\source\repos\$latestVersion\.dotnet";

Invoke-Expression "$PSScriptRoot\DotnetProjectCreationScripts.ps1 -Sdk $latestVersion -BlazorWasmVersion $BlazorWasmVersion";