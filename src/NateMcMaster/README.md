The C# compiler in the .NET 5 SDK can be invoked like

```bash
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll -version
3.8.0-5.20604.10 (9ed4b774)
```

> NOTE: At the moment the latest sdk version is 5.0.103 (patch 3 of the 100 feature band used by visual studio 16.8.x). Every patch is an in-place update to the sdk, so a future 5.0.104 will overwtite the 5.0.103. But the coming 5.0.200 sdk, used by vs2019 16.9, will install side-by-side the latest 5.0.1nn version.

> NOTE: The version of Roslyn can also be computed by writing `#version` in a c# file

```csharp
#version
class Program
{
    static void Main(string[] args)
        => System.Console.WriteLine("Hello World!");
}
```

Lets try to compile this file into an assembly with the above `.entrypoint`

```bash
# This does not work (because it uses the runtime assmeblies in the shared framework)
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll \
    -reference:/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.3/System.Runtime.dll \
    -reference:/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.3/System.Console.dll \
    -out:Program.dll Program.cs
# this works (because it uses the correct compile-time TFM specific reference assemblies)
$ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll \
    -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Runtime.dll \
    -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Console.dll \
    -out:Program.dll Program.cs
```

> NOTE: We are _not_ using the shared framework assemblies. Instead we are using the TFM specific reference assemblies onm the so-called `target packs`. These are like C/C++ header files, or COM type libraries, or IDL files, or whatnot, that only define API interfaces (signatures). In .NET this is metadata without any IL code/implementation.

> NOTE: `System.Runtime` is the core assembly (aka corelib) library in the the `net5.0` target pack, and `System.Console` is another BCL library from `dotnet/runtime`. The corelib can be defined as the only library without a reference to any other managed library (where System.Object` is defined).

> NOTE: The `.dll` extension is a .NET Core convention, not a requirement. If not specified, the compiler will produce a file named `Program.exe`. On Windows, this would be a little misleading because you can’t double-click Program.exe, so in .NET Core we always use `.dll`. On Linux this is just weird, because (native) dynamic libraries normally have an `.so` extension, but .NET uses both PE file format (by specification, and not the Linux ELF file format) and a windows inspired extension (by convention), so we just accept that and move on. The convention totally makes sense, because a managed executable like `csc.dll` does need not a host to run, because everything in .NET user code is a DLL.

> NOTE: The referenced assemblies are from the target packs of the `Microsoft.NETCore.App` shared framework. This used to by a metapackage distributed via NuGet. But in modern .NET Core it turned out that this kind of turned into "package hell" for users to explicitly reference the package graph in msbuild files, so now the shared framework is part of the SDK.

If we try to run the `Program.dll` managed assembly (portable executable) via the `dotnet` host we get and error

```bash
$ dotnet Program.dll
Cannot use file stream for [/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/Program.deps.json]: No such file or directory
A fatal error was encountered. The library 'libhostpolicy.so' required to execute the application was not found in '/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/'.
Failed to run as a self-contained app.
  - The application was run as a self-contained app because '/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/Program.runtimeconfig.json' was not found.
  - If this should be a framework-dependent app, add the '/home/maxfire/repos/github.com/maxild/ILProgramming/src/NateMcMaster/Program.runtimeconfig.json' file and specify the appropriate framework.
```

The .NET Core host cannot find a required `Program.runtimeconfig.json` file. All framework=dependent applications need this file. This JSON file configures options for the runtime.

>  The library 'libhostpolicy.so' required to execute the application was not found along side the managed executable.

To resolve this, create a file named Program.runtimeconfig.json with these contents:

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
