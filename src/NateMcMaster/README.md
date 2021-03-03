Credits go to https://natemcmaster.com/blog/2017/12/21/netcore-primitives/

## .NET commandline compiling (without MSBuild SDK)

> NOTE: This can also be done using ilasm (IL), and probably also the F# compiler
can be used this way (haven't tried it for F# yet)

The C# compiler (Roslyn) in the .NET 5 SDK can be invoked like

```bash
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll -version
3.8.0-5.20604.10 (9ed4b774)
# I can confirm that the most recent version of Roslyn shipping with 5.0.2xx is 3.9.0-3.21056.4.
$ dotnet /usr/share/dotnet/sdk/5.0.200/Roslyn/bincore/csc.dll -version
3.9.0-5.21120.8 (accdcb77)
```

> NOTE: At the moment the latest sdk version is 5.0.103 (patch 3 of the 100 feature band used by visual studio 16.8.x). Every patch is an in-place update to the sdk, so a future 5.0.104 will overwtite the 5.0.103. But the coming 5.0.200 sdk, used by vs2019 16.9, will install side-by-side the latest 5.0.1nn version.

> NOTE: The version of Roslyn can also be computed by writing `#error version` in a c# file

```csharp
class Program
{
    static void Main(string[] args)
        => System.Console.WriteLine("Hello World!");
}
```

Lets try to compile this file into an assembly with the above `.entrypoint`

```bash
# This does not work (because it uses the runtime/implementation assemblies in the shared framework)
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll \
    -reference:/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.3/System.Runtime.dll \
    -reference:/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.3/System.Console.dll \
    -out:Program.dll Program.cs
# this works (because it uses the correct compile-time/reference assemblies from the TFM specific "reference pack")
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll \
    -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Runtime.dll \
    -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Console.dll \
    -out:Program.dll Program.cs
```

> NOTE: We are _not_ using the shared framework assemblies. Instead we are using the TFM specific reference assemblies from the so-called `target/reference pack`. These are like C/C++ header files, or COM type libraries, or IDL files, or whatnot, that only define API interfaces (signatures). In .NET this is metadata without any IL code/implementation.

> NOTE: When you run your code, it loads a different .dll, called the implementation (runtime) assembly, which provides implementations of the contract. This is done so you can compile your app once against the 5.0.0 'contract', and you can update your app to the 5.0.1 and 5.0.2 (etc.) implementations without needing to recompile your code. So, when you're in Visual Studio and click "go to definition", it can only tell you about the reference assembly...since that is what the compiler knows about.

> NOTE: `System.Runtime` is the core assembly (aka corelib) library in the the `net5.0` target pack, and `System.Console` is another BCL library from `dotnet/runtime`. The corelib can be defined as the only library without a reference to any other managed library (where System.Object` is defined).

> NOTE: The `.dll` extension is a .NET Core convention, not a requirement. If not specified, the compiler will produce a file named `Program.exe`. On Windows, this would be a little misleading because you can’t double-click Program.exe, so in .NET Core we always use `.dll`. On Linux this is just weird, because (native) dynamic libraries normally have an `.so` extension, but .NET uses both PE file format (by specification, and not the Linux ELF file format) and a windows inspired extension (by convention), so we just accept that and move on. The convention totally makes sense, because a managed executable like `csc.dll` does need a host to run, because everything in .NET (user) code is a DLL.

> NOTE: The referenced assemblies are from the target packs of the `Microsoft.NETCore.App` shared framework. This used to by a metapackage distributed via NuGet. But it was dicovered around 3.0 that this was to much "package config" for users of the framework, because thay had to use explicit references to too many packageas of the package graph, so now the shared framework is part of the SDK, and you sort of reference everything by default (The graph is trimmed at publish-time, I guess!!!).

> NOTE: Starting .NET Core 3.0, the reference assemblies are no longer part of the NuGetFallbackFolder. Instead, they ship in a "reference pack". On Linux, those .dlls are now found in `/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/` for `net5.0` (or `/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/3.1.0/ref/netcoreapp3.1/` for `netcoreapp3.1`)

## Runtime and Shared Framework (same thing these days)

If we try to run the `Program.dll` managed assembly (portable executable) via the `dotnet` host we get the following error

```bash
$ dotnet Program.dll
Cannot use file stream for [/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/Program.deps.json]: No such file or directory
A fatal error was encountered. The library 'libhostpolicy.so' required to execute the application was not found in '/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/'.
Failed to run as a self-contained app.
  - The application was run as a self-contained app because '/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/Program.runtimeconfig.json' was not found.
  - If this should be a framework-dependent app, add the '/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/Program.runtimeconfig.json' file and specify the appropriate framework.
```

The .NET Core host cannot find a required `Program.runtimeconfig.json` file. All framework-dependent apps need this file. This JSON file configures options for the runtime, and also define which runtime to load to service your app with jit, gc etc.

>  The library 'libhostpolicy.so' required to execute the application was not found along side the managed executable.

To resolve this, create a file named `Program.runtimeconfig.json` with this content

```json
{
  "runtimeOptions": {
    "tfm": "net5.0",
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "5.0.0"
    }
  }
}
```

These options instruct dotnet to use the Microsoft.NETCore.App 5.0.0 shared framework. Even though I only have 5.0.3 installed on my machine the so-called rolled forward policy will just use this latest versiion of the 5.x.y shared framework (aka runtime).

> NOTE: Even though I have updated the SDK to 5.0.200, the included runtimes are still unchanged compared with SDK 5.0.103

- .NET Runtime 5.0.3 (`Microsoft.NETCore.App`)
- ASP.NET Core Runtime 5.0.3 (`Microsoft.AspNetCore.App`)
- .NET Desktop Runtime 5.0.3

> NOTE: `Framework-dependent apps` use the target framework version with a ".0" patch version (for the `runtimeOptions.framework.version` value), and `Self-contained apps` use the latest corresponding patch version (from when the SDK shipped).

> NOTE: The `runtimeconfig.json` file will also configure the .NET host to probe for `System.*` (BCL) assemblies in the shared framework folder at runtime. The (runtime) assemblies are then loaded from `/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.3/` on my Linux machine.

## External references to packages

Probing (resolving) assemblies outside the AppBase directory.

`deps.json`....

Add a file named `Program.deps.json` into your project with these contents.

```json
{

}
```

1. `*.runtimeconfig.dev.json` (best option)
2. `--additionalprobingpath` option
3. `*.runtimeconfig.json` additional probing paths

additional probing paths are for folder layouts that typically come from nuget packages.

Additional deps is a way to augment the list of assemblies available to an application that were not present during the compilation/publish step of building an app.

## MSBuild

Spec for `deps.json`, `runtimeconfig.json` and `runtimeconfig.dev.json`: https://github.com/dotnet/cli/blob/master/Documentation/specs/runtime-configuration-file.md

The `MyApp.runtimeconfig.json` is designed to be user-editable (in the case of an app consumer wanting to change various CLR runtime options for an app, much like the MyApp.exe.config XML file works in .NET 4.x today).

The `MyApp.deps.json` file is designed to be processed by automated tools and should not be user-edited. We could use a different format for the deps file, but if we're already integrating a JSON parser into the host, it seems most appropriate to re-use that here. Also, there are diagnostic benefits to being able to read the .deps.json file in a simple text editor.

The `.deps.json` file has a `libraries` section that will contain a union (aka the transitive closure) of all the dependencies found in the various targets, and contains common metadata for them. Specifically, it contains:

- `type` - the type of the library. `package` for NuGet packages. `project` for a project reference. Can be other things as well.
- `path` - in the package library this is a `relative path` where to find the assets.
- `serviceable` - a boolean indicating if the library can be serviced (only for package-typed libraries)
- `sha512` - SHA-512 hash of the package file (package-typed libraries).
- `hashPath` - in the package library this is a relative path to the .nupkg.sha512 hash file.

`Microsoft.Extensions.DependencyModel` uses the `.deps.json` file to allow a running managed application to query various data about it's dependencies.

For example:
- To find all dependencies that depend on a particular package (used by ASP.NET MVC and other plugin-based systems to identify assemblies that should be searched for possible plugin implementations)
- To determine the reference assemblies used by the application when it was compiled in order to allow runtime compilation to use the same reference assemblies (used by ASP.NET Razor to compile views)
- To determine the compilation settings used by the application in order to allow runtime compilation to use the same settings (also used by ASP.NET Razor views).

Some of the sections in the `.deps.json` file contain data used for runtime compilation. This data is not provided in the file by default. Instead, an MSBuild property `PreserveCompilationContext` must be set to true (typically in the project file) in order to ensure this data is added. Without this setting, the `compilationOptions` will not be present in the file, and the targets section will contain only the runtime dependencies.
Note that ASP.NET projects (those using `Microsoft.NET.Sdk.Web` SDK) has this property set to true by default. Any Razor host using the Razor language package will need it and MVC and Razor Pages are two examples hosting Razor.

## Framework-dependent Deployment Model

An application can be deployed in a "framework-dependent" deployment model. In this case, the RID-specific assets of packages are published within a folder structure that preserves the RID metadata. However the host does not use this folder structure, rather it reads data from the `.deps.json` file.

In the framework-dependent deployment model, the `*.runtimeconfig.json` file will contain the `runtimeOptions.framework` section:

```json
{
  "runtimeOptions": {
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "1.0.1"
      }
  }
}
```

**This data is used to locate the shared framework folder**

In general, it locates the shared runtime in the shared folder located beside it by using the relative path `shared/[runtimeOptions.framework.name]/[runtimeOptions.framework.version]`. Once it has applied any version roll-forward logic and come to a final path to the shared framework, it locates the `[runtimeOptions.framework.name].deps.json` file within that folder and loads it first.

Next, the deps file from the application is loaded and (conceptually) merged into this deps file. Data from the app-local deps file trumps data from the shared framework.

## Assembly resolution

Corehost will first look for a file named "somelib.dll" int the same folder as the main dll. It then probes for additional locations typically listed via `runtimeconfig.dev.json`. Some of these locations are automatic, like `$DOTNET_ROOT/store/`. Others must be specified, like local `./packages` folder which are listed as 'additionalProbingPaths' in the `runtimeconfig.json` or `runtimeconfig.dev.json` file.

In most .NET Core apps, there are actually several `.deps.json` files, one for the app, one for each shared framework, and potentially several additional `deps`, based on your hosting environment, like Azure or AWS. A list of all these files can be retrieved from `System.AppContext.GetData("APP_CONTEXT_DEPS_FILES")`.

Old Spec https://github.com/dotnet/cli/blob/v2.0.0/Documentation/specs/corehost.md

The shared host locates assemblies and native libraries using a combination of: Servicing Index, Files in the application folder (aka "app-local") and files from package caches.

The `runtimeconfig.json` file is used to determine settings to apply to the runtime during initialization and for building the TPA and Native Library Search Path lists. See the spec for the runtime configuration file for more information.

Any file with the suffix `.dll` in the same folder as the managed application being loaded (the "Application Base") will be considered a viable assembly during the resolution process. The host assumes that the assembly's short name is the same as the file name with the .dll suffix removed (yes, this is not technically required by the CLR, but we assume it for use with this host).

Only assemblies listed in the `deps.json` file can be resolved from a package cache. To resolve those assemblies, two environment variables are used:

- `DOTNET_PACKAGES` - The primary package cache. If not set, defaults to `$HOME/.nuget/` packages on Unix or `%LOCALAPPDATA%\NuGet\Packages` (TBD: This has changed) on Windows.
- `DOTNET_PACKAGES_CACHE` - The secondary cache. This is used by shared hosts (such as Azure) to provide a cache of pre-downloaded common packages on a faster disk. If not set, it is not used.

Given the Package ID, Package Version, Package Hash and Asset Relative Path provided in the runtime configuration file, and the assembly is not serviced (see the full resolution algorithm below) resolution proceeds as follows (Unix-style paths will be used for convenience but these variables and paths all apply to Windows as well):

1. If `DOTNET_PACKAGES_CACHE` is non-empty, read the file `$DOTNET_PACKAGES_CACHE/[Package ID]/[Package Version]/[Package Id].[Package Version].nupkg.sha512` if present. If the file is present and the content matches the `[Package Hash]` value from the `deps.json` file. Use that location as the Package Root and go to 3
2. Using `DOTNET_PACKAGES`, or it's default value, use `$DOTNET_PACKAGES/[Package ID]/[Package Version]` as the Package Root
3. Concatenate the Package Root and the Asset Relative Path. This is the path to the asset (managed assembly or native library).

## Other

There are tasks that generate `deps.json` and `runtimeconfig.json` files.

https://github.com/dotnet/sdk/blob/master/src/Tasks/Microsoft.NET.Build.Tasks/targets/GenerateDeps/GenerateDeps.proj

https://github.com/dotnet/sdk/blob/217ba8dc050abf795d82c8e2eb424ff2f81b6577/src/Tasks/Microsoft.NET.Build.Tasks/targets/Microsoft.NET.Sdk.targets#L37-L38

The `global.json` file is used to determine the version of the SDK that is used. It is mean to be committed into source code, but not published with your application when you deployed it. `runtimeconfig.json`, on the other hand, is meant to be part of the application, and you must deploy it with your app.

The .NET Core SDK can be used to build multiple versions of .NET Core applications. For example, with the latest .NET Core SDK (version 5.0.103) you could build a `netcoreapp3.1` or `net5.0` project. If you use the default SDK values, these projects would generated a `runtimeconfig.json` files with `runtimeOptions.framework.version` set to 3.1.0(?haven't tested?) or 5.0.0, respectively.

You can also how .NET Core is parsing the `.deps.json` file by setting the `COREHOST_TRACE` environment variable to 1. (Heads up, this dumps massive amounts of logging to stderr). Look through the trace for some output that says things like "Processing TPA for deps entry" or "Property TRUSTED_PLATFORM_ASSEMBLIES = ...".

```bash
COREHOST_TRACE=1 dotnet Program.dll 2>log.txt
```
