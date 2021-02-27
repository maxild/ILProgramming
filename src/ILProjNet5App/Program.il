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
.assembly extern ILProjNet5Lib
{
  .ver 1:0:0:0
}
.assembly ILProjNet5App
{
  .ver 1:0:0:0
}

// .NET Core uses dll extension by convention (giving it extension 'dll' or 'exe' changes nothing, but all assemblies are DLL's)
// Module is idenfied by its filename (any extension is mandatory)
.module ILProjNet5App.dll

// namespace does not add any metadata (only a DRY way to add prefix)
.namespace ILProjNet5App {
  // TypeDef metadata: each class, struct, enumeration is described by a TypeDef record in the metadata
  // auto (memory) layout
  // ansi string conversions between System.Styring and C-style (ummanaged) strings of bytes.
  // beforefieldinit
  // [CORE_ASSEMBLY]System.Object is a TypeRef with AssemblyRef=System.Runtime
  .class public abstract auto ansi sealed beforefieldinit Program extends [CORE_ASSEMBLY]System.Object
  {
    .method public hidebysig static int32 Main() cil managed
    {
      .maxstack 2
      .entrypoint
      .locals init (int32 Retval)

      // load the string constant (literal) onto the stack
      ldstr "result = "
      // load the constant of type int32 onto the stack (ldc.i4.3 is equivalent?!?)
      ldc.i4 3
      // cal the static method (using a MemberRef) of type int32(int32)
      call int32 [ILProjNet5Lib]ILProjNet5Lib.Class3::Square(int32)
      // store...
      stloc.0
      // load
      ldloca.s 0
      call instance string [CORE_ASSEMBLY]System.Int32::ToString()
      call string [CORE_ASSEMBLY]System.String::Concat(string, string)
      // call MemberRef with type 'void(string)'
      // NOTE: MemberRefs cover both references to FieldDefs and MethodDefs!!!
      call void [System.Console]System.Console::WriteLine(string)

      ldloc Retval
      // return the (single) element of type int32
      // JIT compiler will throw of stack does not contain single element of type int32
      ret
      // stack is empty (or same as before Main was called)
    }
  }
}