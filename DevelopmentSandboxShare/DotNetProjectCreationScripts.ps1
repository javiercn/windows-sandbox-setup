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
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Web API template
dotnet new web -o .\WebApiNoAuth\WebApiNoAuth;
Push-Location WebApiNoAuth;
dotnet new sln;
dotnet sln add .\WebApiNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Razor pages
dotnet new webapp -o .\RazorPagesNoAuth\RazorPagesNoAuth;
Push-Location RazorPagesNoAuth;
dotnet new sln;
dotnet sln add .\RazorPagesNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Razor pages with Identity and local DB
dotnet new webapp -au Individual -uld -o .\RazorPagesIndividualLocalDb\RazorPagesIndividualLocalDb;
Push-Location RazorPagesIndividualLocalDb;
dotnet new sln;
dotnet sln add .\RazorPagesIndividualLocalDb;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Razor pages with Identity and SQL lite
dotnet new webapp -au Individual -o .\RazorPagesIndividualSqlLite\RazorPagesIndividualSqlLite;
Push-Location RazorPagesIndividualSqlLite;
dotnet new sln;
dotnet sln add .\RazorPagesIndividualSqlLite;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Razor pages with Razor class library
dotnet new webapp -o .\RazorPagesWithClassLib\RazorPagesWithClassLib;
dotnet new razorclasslib -s -o .\RazorPagesWithClassLib\RazorClassLibPagesAndViews;
Push-Location RazorPagesWithClassLib;
dotnet new sln;
dotnet sln add .\RazorPagesWithClassLib;
dotnet sln add .\RazorClassLibPagesAndViews;
dotnet add .\RazorPagesWithClassLib reference .\RazorClassLibPagesAndViews;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# MVC
dotnet new mvc -o .\MvcNoAuth\MvcNoAuth;
Push-Location MvcNoAuth;
dotnet new sln;
dotnet sln add .\MvcNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# MVC with Identity and local DB
dotnet new mvc -au Individual -uld -o .\MvcIndividualLocalDb\MvcIndividualLocalDb;
Push-Location MvcIndividualLocalDb;
dotnet new sln;
dotnet sln add .\MvcIndividualLocalDb;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# MVC with Identity and SQL lite
dotnet new mvc -au Individual -o .\MvcIndividualSqlLite\MvcIndividualSqlLite;
Push-Location MvcIndividualSqlLite;
dotnet new sln;
dotnet sln add .\MvcIndividualSqlLite;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# MVC with Razor class library
dotnet new mvc -o .\MvcWithClassLib\MvcWithClassLib;
dotnet new razorclasslib -s -o .\MvcWithClassLib\RazorClassLibPagesAndViews;
Push-Location MvcWithClassLib;
dotnet new sln;
dotnet sln add .\MvcWithClassLib;
dotnet sln add .\RazorClassLibPagesAndViews;
dotnet add .\MvcWithClassLib reference .\RazorClassLibPagesAndViews;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Server-side Blazor
dotnet new blazorserver -o .\BlazorServerNoAuth\BlazorServerNoAuth;
Push-Location BlazorServerNoAuth;
dotnet new sln;
dotnet sln add .\BlazorServerNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Server-side Blazor with Identity and local DB
dotnet new blazorserver -au Individual -uld -o .\BlazorServerIndividualLocalDb\BlazorServerIndividualLocalDb;
Push-Location BlazorServerIndividualLocalDb;
dotnet new sln;
dotnet sln add .\BlazorServerIndividualLocalDb;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Server-side Blazor with Identity and SQL lite
dotnet new blazorserver -au Individual -o .\BlazorServerIndividualSqlLite\BlazorServerIndividualSqlLite;
Push-Location BlazorServerIndividualSqlLite;
dotnet new sln;
dotnet sln add .\BlazorServerIndividualSqlLite;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Server-side Blazor with Razor class library
dotnet new blazorserver -o .\BlazorServerWithClassLib\BlazorServerWithClassLib;
dotnet new razorclasslib -o .\BlazorServerWithClassLib\RazorClassLibNoPages;
Push-Location BlazorServerWithClassLib;
dotnet new sln;
dotnet sln add .\BlazorServerWithClassLib;
dotnet sln add .\RazorClassLibNoPages;
dotnet add .\BlazorServerWithClassLib reference .\RazorClassLibNoPages;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Angular
dotnet new angular -o .\AngularNoAuth\AngularNoAuth;
Push-Location AngularNoAuth;
dotnet new sln;
dotnet sln add .\AngularNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Angular with Identity and local DB
dotnet new angular -au Individual -uld -o .\AngularIndividualLocalDb\AngularIndividualLocalDb;
Push-Location AngularIndividualLocalDb;
dotnet new sln;
dotnet sln add .\AngularIndividualLocalDb;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# Angular with Identity and SQL lite
dotnet new angular -au Individual -o .\AngularIndividualSqlLite\AngularIndividualSqlLite;
Push-Location AngularIndividualSqlLite;
dotnet new sln;
dotnet sln add .\AngularIndividualSqlLite;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# React
dotnet new react -o .\ReactNoAuth\ReactNoAuth;
Push-Location ReactNoAuth;
dotnet new sln;
dotnet sln add .\ReactNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# React with Identity and local DB
dotnet new react -au Individual -uld -o .\ReactIndividualLocalDb\ReactIndividualLocalDb;
Push-Location ReactIndividualLocalDb;
dotnet new sln;
dotnet sln add .\ReactIndividualLocalDb;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# React with Identity and SQL lite
dotnet new react -au Individual -o .\ReactIndividualSqlLite\ReactIndividualSqlLite;
Push-Location ReactIndividualSqlLite;
dotnet new sln;
dotnet sln add .\ReactIndividualSqlLite;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
Pop-Location;

# ReactRedux
dotnet new reactredux -o .\ReactReduxNoAuth\ReactReduxNoAuth;
Push-Location ReactReduxNoAuth;
dotnet new sln;
dotnet sln add .\ReactReduxNoAuth;
dotnet new gitignore;
git init;
git add .gitignore;
git commit -m "Add .gitignore";
git add .;
git commit -m "Initial commit";
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
    dotnet new gitignore;
    git init;
    git add .gitignore;
    git commit -m "Add .gitignore";
    git add .;
    git commit -m "Initial commit";
    Pop-Location;

    # Blazor wasm hosted
    dotnet new blazorwasm -ho -o .\BlazorWasmHosted;
    dotnet new gitignore;
    git init;
    git add .gitignore;
    git commit -m "Add .gitignore";
    git add .;
    git commit -m "Initial commit";
}

# Leaves $repos
Pop-Location;