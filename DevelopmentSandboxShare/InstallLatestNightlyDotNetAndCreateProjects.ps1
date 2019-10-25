param(
  [string] $Branch
)

# Change acordingly in previews
$BlazorWasmVersion = "3.1.0-preview2.*";

$latestVersion = ((Invoke-WebRequest "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/release/$($Branch)xx/latest.version" | Select-Object -ExpandProperty Content) -split "\n" | Where-Object { $_ -like "$Branch*" }).Trim();

C:\Users\WDAGUtilityAccount\Desktop\DevelopmentSandboxShare\dotnet-install.ps1 -version $latestVersion -InstallDir "$env:USERPROFILE\source\repos\$latestVersion\.dotnet";

$feeds = @"
<configuration>
  <packageSources>
    <add key="dotnet-core" value="https://dotnetfeed.blob.core.windows.net/dotnet-core/index.json" />
    <add key="dotnet-windowsdesktop" value="https://dotnetfeed.blob.core.windows.net/dotnet-windowsdesktop/index.json" />
    <add key="aspnet-aspnetcore" value="https://dotnetfeed.blob.core.windows.net/aspnet-aspnetcore/index.json" />
    <add key="aspnet-aspnetcore-tooling" value="https://dotnetfeed.blob.core.windows.net/aspnet-aspnetcore-tooling/index.json" />
    <add key="aspnet-entityframeworkcore" value="https://dotnetfeed.blob.core.windows.net/aspnet-entityframeworkcore/index.json" />
    <add key="aspnet-extensions" value="https://dotnetfeed.blob.core.windows.net/aspnet-extensions/index.json" />
    <add key="gRPC repository" value="https://grpc.jfrog.io/grpc/api/nuget/v3/grpc-nuget-dev" />
    <add key="blazor" value="https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet3.1/nuget/v3/index.json" />
  </packageSources>
</configuration>
"@;

Set-Content $feeds -Path "$env:USERPROFILE\source\repos\$latestVersion\nuget.config";

Invoke-Expression "$PSScriptRoot\DotnetProjectCreationScripts.ps1 -Sdk $latestVersion -BlazorWasmVersion $BlazorWasmVersion -BlazorWasmNugetSource `"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet3.1/nuget/v3/index.json`"";