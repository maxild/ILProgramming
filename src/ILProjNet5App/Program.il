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
.assembly ILProjNet5App
{
  .ver 1:0:0:0
}

.module ILProjNet5App.dll

.namespace ILProjNet5App {
  .class public abstract auto ansi sealed beforefieldinit Program extends [CORE_ASSEMBLY]System.Object
  {
    .method public hidebysig static int32 Main() cil managed
    {
      .entrypoint
      .locals init (int32 Retval)
      .maxstack 2

      ldstr "Hello World!"
      call void [System.Console]System.Console::WriteLine(string)

      ldloc Retval
      ret
    }
  }
}