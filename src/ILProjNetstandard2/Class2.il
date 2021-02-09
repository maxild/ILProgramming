//#include "coreassembly.h"
// NOTE: The following can be found using ildasm
// See https://docs.microsoft.com/en-us/dotnet/standard/assembly/view-contents
// net5.0
// Metadata version: v4.0.30319
// #define CORE_ASSEMBLY "System.Runtime"
// #define CORE_ASSEMBLY_VERSION "4:0:0:0"
// #define CORE_ASSEMBLY_PUBLIC_KEY_TOKEN "B0 3F 5F 7F 11 D5 0A 3A"
// netfx
// #define CORE_ASSEMBLY "mscorlib"
// #define CORE_ASSEMBLY_VERSION ""
// #define CORE_ASSEMBLY_PUBLIC_KEY_TOKEN ""
// TODO: ildasm netstandard.dll but which one (the reference/comnpile-time assembly)
// netstandard2.0
// #define CORE_ASSEMBLY "netstandard"
// #define CORE_ASSEMBLY_VERSION "2:0:0:0"
// #define CORE_ASSEMBLY_PUBLIC_KEY_TOKEN "B7 7A 5C 56 19 34 E0 89"
//                                         CC 7B 13 FF CD 2D DD 51

// CORE_ASSEMBLY is a define for mscorlib, netstandard or System.Runtime
// .assembly extern CORE_ASSEMBLY
// {
//   .publickeytoken = ( CORE_ASSEMBLY_PUBLIC_KEY_TOKEN )
//   .ver CORE_ASSEMBLY_VERSION
// }

// #define CORE_ASSEMBLY "System.Runtime"
// .assembly extern CORE_ASSEMBLY
// {
//   .publickeytoken = ( B0 3F 5F 7F 11 D5 0A 3A )
//   .ver 5:0:0:0
// }

#define CORE_ASSEMBLY "netstandard"
.assembly extern CORE_ASSEMBLY
{
  .publickeytoken = ( CC 7B 13 FF CD 2D DD 51 )
  .ver 2:0:0:0
}

.assembly ILProjNetstandard2
{
  .ver 1:0:0:0
}

.module ILProjNetstandard2.dll

.namespace ILProjNetstandard2 {
  .class public auto ansi Class2
    extends [CORE_ASSEMBLY]System.Object
  {
    .method public hidebysig static int32 SayHello(int32) cil managed
    {
      .maxstack 4

      ldstr "Hello World!"
      call void [CORE_ASSEMBLY]System.Console::WriteLine(string)

      ldarg.0
      ret
    }
  }
}