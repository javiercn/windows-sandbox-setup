param (
    [string]$Sdk = "3.0.100"
)

# Installs .NET global tools that are handy for
# testing purposes

# This is done to install the tools based on the forced SDK
$repos = "$env:USERPROFILE\source\repos\$Sdk";
Push-Location $repos;

dotnet tool install --global dotnet-dump
dotnet tool install --global dotnet-trace
dotnet tool install --global dotnet-counters

Pop-Location