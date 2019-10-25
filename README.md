To use this you need to enable the windows sandbox (see Installation for details).

You can pin the DevelopmentSandbox.wsb file to your task bar and start it by right clicking on it and selecting DevelopmentSandbox.

## Account details

* The user is WDAGUtilityAccount
* To change the password open a command prompt and run net user WDAGUtilityAccount *
* The password will be reset every time you close the sandbox

## Available projects

* The machine creates a list of the most common projects with the latest released SDK ready to go inside C:\Users\WDAGUtilityAccount\sources\repo\3.0.100 (latest SDK)
* The machine creates a list of the most common projects with the latest SDK from [core-sdk](https://github.com/dotnet/core-sdk) at C:\Users\WDAGUtilityAccount\sources\repo\3.1.1* (latest nightly SDK)
  * The nightly SDK is bin installed in `C:\Users\WDAGUtilityAccount\sources\repo\3.1.1*\.dotnet\` so **you need to add it to your path before you launch Visual Studio** to use nightly builds.
* All their projects are locked to their respective SDK versions using a global.json in `C:\Users\WDAGUtilityAccount\sources\repo\*\global.json`

## Installed software and tools

* VS Preview with our workloads.
* VS Code
* Chrome
* Nodejs
* Powershell Core
* The latest dotnet core SDK
* git
* MSBuild structured log viewer
* ILSpy
* Fiddler

# Please do not file issues into this repo