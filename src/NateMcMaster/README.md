Credits go to https://natemcmaster.com/blog/2017/12/21/netcore-primitives/

## .NET commandline compiling (without MSBuild SDK)

> NOTE: This can also be done using ilasm (IL), and probably also the F# compiler
can be used this way (haven't tried it for F# yet)

The C# compiler (Roslyn) in the .NET 5 SDK can be invoked like

```bash
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll -version
3.8.0-5.20604.10 (9ed4b774)
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

There are tasks that generate `deps.json` and `runtimeconfig.json` files.

https://github.com/dotnet/sdk/blob/master/src/Tasks/Microsoft.NET.Build.Tasks/targets/GenerateDeps/GenerateDeps.proj

https://github.com/dotnet/sdk/blob/217ba8dc050abf795d82c8e2eb424ff2f81b6577/src/Tasks/Microsoft.NET.Build.Tasks/targets/Microsoft.NET.Sdk.targets#L37-L38

The `global.json` file is used to determine the version of the SDK that is used. It is mean to be committed into source code, but not published with your application when you deployed it. `runtimeconfig.json`, on the other hand, is meant to be part of the application, and you must deploy it with your app.

The .NET Core SDK can be used to build multiple versions of .NET Core applications. For example, with the latest .NET Core SDK (version 5.0.103) you could build a `netcoreapp3.1` or `net5.0` project. If you use the default SDK values, these projects would generated a `runtimeconfig.json` files with `runtimeOptions.framework.version` set to 3.1.0(?haven't tested?) or 5.0.0, respectively.
