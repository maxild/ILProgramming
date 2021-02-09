# Creating IL projects with .NET SDK (and using ildasm/ilasm tooling in CoreCLR)

Want to learn about the .NET runtime, learn IL!!! It is one important building block (other blocks are GC/memory management, jit, loader etc.)

Goal: Learn more about the `dotnet/runtime` (`Microsoft.NETCore.App`) `5.x.y` (5.0.2) (Note: The SDK versions like `5.x.y.znn`, but the runtime versions according to semver 5.x.y)

This also means learning more about IL. The tools to use (ilasm/ildasm) are the compilers/decompilers to create/inspect managed assemblies (IL + metadata) from IL source code.

Today ilasm/ildasm are not distributed in any user-friendly way. Also the tools a er native and platform dependent,
and they also require being used with the correct runtime (CoreCLR) version.

My guess is there 2 ways to work with IL (learning IL)

1. IL Projects (`Microsoft.NET.Sdk.IL`). This MSBuild SDK wrap the `ilasm` compiler such that .NET Core SDK (command line builds) will work on IL source code. The [System.Runtime.CompilerServices.Unsafe](https://github.com/dotnet/runtime/tree/master/src/libraries/System.Runtime.CompilerServices.Unsafe) project in `dotnet/runtime` is the baseline example for inspecting how this works (because it is not well-documented at all).
2. Downloading the tools one by one, and placing them next to the correct CoreCLR binaries (a more manual approach)

NOTE: https://stackoverflow.com/questions/59595350/ildasm-on-linux-via-nuget-installation-ildasm-executable-not-found will show you how to install ildasm/ilasm on Linux.

## Build tool packages

- `Microsoft.NET.Sdk.IL`
- `Microsoft.NETCore.ILDasm`
- `runtime.win-x64.Microsoft.NETCore.ILAsm`
- `runtime.linux-x64.Microsoft.NETCore.ILAsm`
- `runtime.osx-x64.Microsoft.NETCore.ILAsm`
- etc....many runtime IDs....

## Github issues

1. Make ildasm and ilasm global (standalone) tools (today the tools only ship within the ilproj SDK)...TODO
2. etc

## Notes

Grouped into the 2 approaches.

## IlDasm / ILAsm notes

- Both the `ildasm` and `ilasm` tools are built with CoreCLR from this repo: https://github.com/dotnet/runtime. They include similar functionality as the versions shipped with Windows (desktop CLR) (sans GUI, etc.).
- There are nuget packages shipped that include them as well (https://www.nuget.org/packages?q=ildasm), but they are platform-specific and also require a matching version of CoreCLR to use, so they are not straightforward to consume via nuget. The easiest way to run these on your platform is to just build them from source from the dotnet/runtime repo.
- https://stackoverflow.com/questions/39979851/net-core-equivalent-of-ildasm-ilasm
- The .NET Core variants of `ILAsm` and `ILDasm` depend on core assets of the build of the same CoreCLR version they are built for. If they are restored via a dependency graph, a self-contained .net core deployment depending on `Microsoft.NETCore.ILAsm` should contain all assets for the target runtime.
- To get the extracted version of `ilasm.exe` / `ildasm.exe` to work without doing that, you need to copy the `coreclr.dll` from the matching .net core version into the same directory. This file can be found in `C:\Program Files\dotnet\shared\Microsoft.NETCore.App\2.0.0` if a .NET Core 2.0.0 runtime is installed in its default location (on Windows).
- https://github.com/dotnet/runtime/issues/38703 shows how to get up and running using dotnet/sdk.
- In .NET Core 3.x the CoreCLR binary (libcoreclr.so) need to be side by side with the `ilasm` and `ildasm`. The earlier workaround was to remove the `false` after the `--self-contained`, since then the whole runtime is copied into the target folder. In .NET 5 this was fixed by dotnet/coreclr#25930 and related PRs that made `ilasm`/`ildasm` standalone tools (ildasm/ilasm have stopped depending on coreclr shared library, instead those binaries are now statically linked against all of the metadata logic), and the workaround should no longer be necessary. That is the `Microsoft.NETCore.ILAsm` and `Microsoft.NETCore.ILDasm` packages to not depend on the CoreCLR package.

## Methods to install ildasm/ilasm

### Method 1: Publish self-contained net5.0 dummy app

```bash
$ mkdir test && cd test
$ dotnet new console
$ dotnet add package Microsoft.NETCore.ILAsm (ILDAsm)
$ dotnet publish -c Release --self-contained false --runtime linux-x64
$ touch test.il
$ ./bin/Release/net5.0/linux-x64/publish/ilasm test.il
```

### Method 2: Download internal implementation nuget package (and know what you are doing)

1. Get the RID

```bash
$ dotnet --info
```

2. Download the package runtime.{RID}.Microsoft.NETCore.ILDAsm. For my case it is: `runtime.linux-x64.Microsoft.NETCore.ILDAsm`

3. Unarchive it and extract executable file '/runtimes/{RID}/native/ildasm'

4. grant it execution permission and copy to .NET runtime folder (call dotnet --list-runtimes to list runtimes). It is no longer necessary to copy the tools next to coreclr (they have become standalone tools that have been statically compiled with their CoreClr dependency, no LD_LIBRARY_PATH path nonsense)

```bash
$ chmod +x ildasm
$ # sudo mv ildasm /usr/share/dotnet/shared/Microsoft.NETCore.App/{version}/
```

5. create symlink (if desired, or bash wrapper, or whatever)

```bash
$ # ln -s /usr/share/dotnet/shared/Microsoft.NETCore.App/{version}/ildasm ildasm

6. run ildasm

```bash
$ ./ildasm {path}/project.dll >> {path}/project.il
```

### IL Proj notes

- https://github.com/JonHanna/Mnemosyne
- https://github.com/Konard/ILProj
- https://www.strathweb.com/2019/12/creating-common-intermediate-language-projects-with-net-sdk/
- https://laptrinhx.com/write-net-standard-library-directly-by-assembly-1892579106/
- https://youtrack.jetbrains.com/issue/RIDER-32352
- the IL tools SDK is available on nuget.org for .NET 5.0 (e.g. https://www.nuget.org/packages/Microsoft.NET.Sdk.IL/). The package provides support for building IL projects.
- The IL compilers have no easy to use (or well-known) nuget package. Something like this Roslyn (C#) [Microsoft.Net.Compilers.Toolset](https://www.nuget.org/packages/Microsoft.Net.Compilers.Toolset/) is missing.
- `System.Runtime.CompilerServices.Unsafe` package uses 'Microsoft.NET.Sdk.IL' (go inspect the sources)
- In addition to `Reflection.Emit` you can write your il code in text file and use `ilasm` to create assembly.
You can use `ildasm` to get il text file to see the structure.
- It should be noted that the JIT optimization of the (Core)CLR depends on the specific mode of CIL. Directly using CIL to program instead of using the Roslyn compiler to generate specific mode of CIL may lead to optimization failure, such as vectorization, pattern matching cache, constant time optimization, etc., so it is better to use CIL directly to program the JIT of CLR. The source code of JIT is https://github.com/dotnet/runtime/tree/master/src/coreclr/src/jit.

## Use Cases

### Understand Roslyn better

TODO

### Understand the runtime better

The runtime (CLR, CoreCLR) will read IL source (and metadata) and generates machine code that will be executed by the OS/hardware platform. IL is equivalent to (modern x86-64) ASM assembly code in the (Core)CLR when runnning on 64-bit Linux. MacOS or Windows.

### Bypass the common type system (CTS).

We need to bypass the type system and “cut holes” in it.

### IL Weaving (optimize for performance)

Imagine you're writing a serializer

Your typical code will look like this

```csharp
Serialize(Object value, Writer writer)
{
    foreach (var property in value.GetType().GetProperties())
    {
        writer.WriteProperty(property.Name, property.GetValue(value));
    }
}
```

which does a lot of metadata walking and indirect method invocations, which is slow (about 200x slower the direct property access the list time I tried bencmarking)

You can use `Reflection.Emit` to generate code that will be equivalent to this C# for each type:

```csharp
Serialize(MyType value, Writer writer)
{
    writer.Write("MyTypeProperty", value.MyTypeProperty);
    writer.Write("MyTypeOtherProperty", value.MyTypeOtherProperty);
    writer.Write("MyTypeAnotherProperty", value.MyTypeAnotherProperty);
    writer.Write("MyTypeSomeProperty", value.MyTypeSomeProperty);
}
```

Then you get this delegate, store it into `Dictionary<Type, Action<object, Writer>>` and use it. It will have startup cost, but it will be as fast as code written by hand in C#.

Libraries that use it, for example: `Automapper`, Microsoft Dependency Injection.

`System.Reflection.Emit.DynamicMethod` and `ILGenerator` to create a delegate and invoke it.

## IL Projects

You should be able to consume the ILProj SDK this way:

1. Add a reference to the MyGet feed containing the NuGet Package (https://dotnet.myget.org/F/dotnet-core/api/v3/index.json)
2. Add a `global.json` to the root of your repository containing the `msbuild-sdk` info (replacing the version as appropriate):

```json
{
  "msbuild-sdks": {
    "Microsoft.NET.Sdk.IL": "3.0.0-preview1-26824-01"
  }
}
```

3. Updating your project to reference the SDK: `<Project Sdk="Microsoft.NET.Sdk.IL">`

Note: There is no Visual Studio Project System support for now. See: [dotnet/arcade#317 (comment)](https://github.com/dotnet/arcade/pull/317#issuecomment-404566671)

A bare bones ilproj would look like:

```xml
<?xml version="1.0"?>
<Project Sdk="Microsoft.NET.Sdk.IL">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netcoreapp2.1</TargetFramework>
  </PropertyGroup>

</Project>
```

I validated locally that this works with `System.Runtime.CompilerServices.Unsafe.ilproj`
