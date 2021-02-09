#include "coreassembly.h"

.assembly ILProjNet5
{
  .ver 1:0:0:0
}

.module ILProjNet5.dll

.class public abstract auto ansi sealed beforefieldinit ILProjNet5.Program
  extends [CORE_ASSEMBLY]System.Object
{
  .method public hidebysig static int32 Main() cil managed
  {
    .maxstack 2

    ldstr "Hello World!"
    call void [System.Console]System.Console::WriteLine(string)

    ret
  }
}