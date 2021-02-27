Edited version of chapter 1 program from the book ".NET IL Assembler". In the book
the source is called `Simple.il`. I have renamed it to `Program.il`.

The edits are made for the code to run on .NET 5 runtime

The P/Invoke is to glibc on linux (`libc.so.6`).

I couldm't get vararg (`call vararg` IL) to work????

The code are build with the "linux-x64" ildasm/ilasm tools from NuGet.org

The managed executable (assembly) is configured with a `runtimeconfig.json` file
such that the `dotnet` host can locate the runtime.

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