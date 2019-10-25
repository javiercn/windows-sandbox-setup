param (
    [string]$Sdk = "3.0.100",
    [string]$BlazorWasmVersion = "",
    [string]$BlazorWasmNugetSource = ""
)
# Creates all the project types with their most common options as a way
# to make issue investigations, repros and validations faster and easier
# to perform.

# Note currently the projects using local DB won't work in the Windows Sandbox

$repos = "$env:USERPROFILE\source\repos\$Sdk";

if (-not (Test-Path $repos)) {
    New-Item -ItemType Directory $repos | Out-Null;
}

Push-Location $repos;
if ($Sdk) {
    dotnet new globaljson --sdk-version $Sdk;
}

# Empty template
dotnet new web -o .\EmptyApp\EmptyApp;
Push-Location EmptyApp;
dotnet new sln;
dotnet sln add .\EmptyApp;
Pop-Location;

# Razor pages
dotnet new webapp -o .\RazorPagesNoAuth\RazorPagesNoAuth;
Push-Location RazorPagesNoAuth;
dotnet new sln;
dotnet sln add .\RazorPagesNoAuth;
Pop-Location;

# Razor pages with Identity and local DB
dotnet new webapp -au Individual -uld -o .\RazorPagesIndividualLocalDb\RazorPagesIndividualLocalDb;
Push-Location RazorPagesIndividualLocalDb;
dotnet new sln;
dotnet sln add .\RazorPagesIndividualLocalDb;
Pop-Location;

# Razor pages with Identity and SQL lite
dotnet new webapp -au Individual -o .\RazorPagesIndividualSqlLite\RazorPagesIndividualSqlLite;
Push-Location RazorPagesIndividualSqlLite;
dotnet new sln;
dotnet sln add .\RazorPagesIndividualSqlLite;
Pop-Location;

# Razor pages with Razor class library
dotnet new webapp -o .\RazorPagesWithClassLib\RazorPagesWithClassLib;
dotnet new razorclasslib -s -o .\RazorPagesWithClassLib\RazorClassLibPagesAndViews;
Push-Location RazorPagesWithClassLib;
dotnet new sln;
dotnet sln add .\RazorPagesWithClassLib;
dotnet sln add .\RazorClassLibPagesAndViews;
dotnet add .\RazorPagesWithClassLib reference .\RazorClassLibPagesAndViews;
Pop-Location;

# MVC
dotnet new mvc -o .\MvcNoAuth\MvcNoAuth;
Push-Location MvcNoAuth;
dotnet new sln;
dotnet sln add .\MvcNoAuth;
Pop-Location;

# MVC with Identity and local DB
dotnet new mvc -au Individual -uld -o .\MvcIndividualLocalDb\MvcIndividualLocalDb;
Push-Location MvcIndividualLocalDb;
dotnet new sln;
dotnet sln add .\MvcIndividualLocalDb;
Pop-Location;

# MVC with Identity and SQL lite
dotnet new mvc -au Individual -o .\MvcIndividualSqlLite\MvcIndividualSqlLite;
Push-Location MvcIndividualSqlLite;
dotnet new sln;
dotnet sln add .\MvcIndividualSqlLite;
Pop-Location;

# MVC with Razor class library
dotnet new mvc -o .\MvcWithClassLib\MvcWithClassLib;
dotnet new razorclasslib -s -o .\MvcWithClassLib\RazorClassLibPagesAndViews;
Push-Location MvcWithClassLib;
dotnet new sln;
dotnet sln add .\MvcWithClassLib;
dotnet sln add .\RazorClassLibPagesAndViews;
dotnet add .\MvcWithClassLib reference .\RazorClassLibPagesAndViews;
Pop-Location;

# Server-side Blazor
dotnet new blazorserver -o .\BlazorServerNoAuth\BlazorServerNoAuth;
Push-Location BlazorServerNoAuth;
dotnet new sln;
dotnet sln add .\BlazorServerNoAuth;
Pop-Location;

# Server-side Blazor with Identity and local DB
dotnet new blazorserver -au Individual -uld -o .\BlazorServerIndividualLocalDb\BlazorServerIndividualLocalDb;
Push-Location BlazorServerIndividualLocalDb;
dotnet new sln;
dotnet sln add .\BlazorServerIndividualLocalDb;
Pop-Location;

# Server-side Blazor with Identity and SQL lite
dotnet new blazorserver -au Individual -o .\BlazorServerIndividualSqlLite\BlazorServerIndividualSqlLite;
Push-Location BlazorServerIndividualSqlLite;
dotnet new sln;
dotnet sln add .\BlazorServerIndividualSqlLite;
Pop-Location;

# Server-side Blazor with Razor class library
dotnet new blazorserver -o .\BlazorServerWithClassLib\BlazorServerWithClassLib;
dotnet new razorclasslib -o .\BlazorServerWithClassLib\RazorClassLibNoPages;
Push-Location BlazorServerWithClassLib;
dotnet new sln;
dotnet sln add .\BlazorServerWithClassLib;
dotnet sln add .\RazorClassLibNoPages;
dotnet add .\BlazorServerWithClassLib reference .\RazorClassLibNoPages;
Pop-Location;

# Angular
dotnet new angular -o .\AngularNoAuth\AngularNoAuth;
Push-Location AngularNoAuth;
dotnet new sln;
dotnet sln add .\AngularNoAuth;
Pop-Location;

# Angular with Identity and local DB
dotnet new angular -au Individual -uld -o .\AngularIndividualLocalDb\AngularIndividualLocalDb;
Push-Location AngularIndividualLocalDb;
dotnet new sln;
dotnet sln add .\AngularIndividualLocalDb;
Pop-Location;

# Angular with Identity and SQL lite
dotnet new angular -au Individual -o .\AngularIndividualSqlLite\AngularIndividualSqlLite;
Push-Location AngularIndividualSqlLite;
dotnet new sln;
dotnet sln add .\AngularIndividualSqlLite;
Pop-Location;

# React
dotnet new react -o .\ReactNoAuth\ReactNoAuth;
Push-Location ReactNoAuth;
dotnet new sln;
dotnet sln add .\ReactNoAuth;
Pop-Location;

# React with Identity and local DB
dotnet new react -au Individual -uld -o .\ReactIndividualLocalDb\ReactIndividualLocalDb;
Push-Location ReactIndividualLocalDb;
dotnet new sln;
dotnet sln add .\ReactIndividualLocalDb;
Pop-Location;

# React with Identity and SQL lite
dotnet new react -au Individual -o .\ReactIndividualSqlLite\ReactIndividualSqlLite;
Push-Location ReactIndividualSqlLite;
dotnet new sln;
dotnet sln add .\ReactIndividualSqlLite;
Pop-Location;

# ReactRedux
dotnet new reactredux -o .\ReactReduxNoAuth\ReactReduxNoAuth;
Push-Location ReactReduxNoAuth;
dotnet new sln;
dotnet sln add .\ReactReduxNoAuth;
Pop-Location;

if ($BlazorWasmVersion -ne "") {
    if ($BlazorWasmNugetSource -ne "") {
        dotnet new --install Microsoft.AspNetCore.Blazor.Templates::$BlazorWasmVersion --nuget-source $BlazorWasmNugetSource;
    }
    else {
        dotnet new --install Microsoft.AspNetCore.Blazor.Templates::$BlazorWasmVersion;
    }

    # Blazor wasm
    dotnet new blazorwasm -o .\BlazorWasmStandalone\BlazorWasmStandalone;
    Push-Location BlazorWasmStandalone;
    dotnet new sln;
    dotnet sln add .\BlazorWasmStandalone;
    Pop-Location;

    # Blazor wasm hosted
    dotnet new blazorwasm -ho -o .\BlazorWasmHosted\BlazorWasmHosted;
}

# Leaves $repos
Pop-Location;