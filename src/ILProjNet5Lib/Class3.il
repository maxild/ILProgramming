#define CORE_ASSEMBLY "System.Runtime"
.assembly extern CORE_ASSEMBLY
{
  .publickeytoken = ( B0 3F 5F 7F 11 D5 0A 3A )
  .ver 5:0:0:0
}
.assembly extern System.Console
{
  .publickeytoken = ( B0 3F 5F 7F 11 D5 0A 3A )
  .ver 5:0:0:0
}
.assembly ILProjNet5Lib
{
  .ver 1:0:0:0
}

.module ILProjNet5Lib.dll

.class public auto ansi ILProjNet5Lib.Class3
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