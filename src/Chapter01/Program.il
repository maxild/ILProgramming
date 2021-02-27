//----------- Program header
// .assembly extern  mscorlib { auto }
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
.assembly Program
{
    .ver 1:0:0:0
}
// Everything is a dll in .net core
// TODO: Cannot get ilasm to output Program.dll (it outputs Program.exe)
.module Program.dll

.class public auto ansi Program extends [CORE_ASSEMBLY]System.Object {
    .method private hidebysig static pinvokeimpl("libc.so.6" ansi cdecl)
        int32 sscanf(string str, int8* format, [out] int32& arg1) cil managed preservesig { }

    .field public static int32 val

    // Normally named Main, but check also works...
    .method public static void check( ) cil managed {
        .entrypoint
        .locals init (int32 Retval)
    AskForNumber:
        ldstr "Enter a number"
        call void [System.Console]System.Console::WriteLine (string)
        // load string to parse from stdin user input (first arg)
        call string [System.Console]System.Console::ReadLine ()
        // load "%d" (second arg) as (ansi) byte array
        ldsflda valuetype CharArray8 Format
        // load System.Int32 static 'val' field
        ldsflda int32 Program::val
        // P/Invoke sscanf from glibc
        // call vararg int32 sscanf(string,int8*,...,int32*)
        call int32 Program::sscanf(string, int8*, int32&)
        // store exit code from sscanf in RetVal locale stack variable
        stloc Retval
        ldloc Retval
        // branch to parse error
        brfalse Error
        // load the parsed value
        ldsfld int32 Program::val
        // load constant one (1)
        ldc.i4 1
        // call and to check for even/odd
        and
        brfalse ItsEven
        ldstr "odd!"
        br PrintAndReturn
    ItsEven:
        ldstr "even!"
        br PrintAndReturn
    Error:
        ldstr "How rude!"
    PrintAndReturn:
        call void [System.Console]System.Console::WriteLine (string)
        ldloc Retval
        brtrue AskForNumber
        ret
    } // End of method
} // End of class

//----------- Global items
.field public static valuetype CharArray8 Format at FormatData

//----------- Data declaration
.data FormatData = bytearray(25 64 00 00 00 00 00 00) // % d . . . . . .

//----------- Value type as placeholder
.class public explicit CharArray8
              extends [CORE_ASSEMBLY]System.ValueType { .size 8  }

//----------- Calling unmanaged code
//    [DllImport("msvcrt", CharSet = CharSet.Ansi, SetLastError=true, CallingConvention = CallingConvention.Cdecl)]
//    static extern int sscanf(string format, __arglist);

//    [DllImport("msvcrt.dll", CharSet=CharSet.Ansi, CallingConvention=CallingConvention.Cdecl)]
//    public static extern int scanf(string format, ref int s1);
//       int sum=0;
//       scanf("%d", ref sum);
//       Console.WriteLine("Using int = {0}", sum);
//    [DllImport("msvcrt.dll", CharSet=CharSet.Ansi, CallingConvention=CallingConvention.Cdecl)]
//    public static extern int scanf(string format, ref string s1);
//       string strSum=" ";
//       scanf("%s", ref strSum); // => NullReferenceException
//       // Omitting 'ref' doesn't throw an exception, but doesn't give me anything
//       // back in 'strSum' of course.
// NOTES: Use System.Text.StringBuilder instead of System.String.
// You should use the StringBuilder class instead. This is the way that
// you pass strings where the content of the string could be modified. Also,
// do not pass it by ref, just pass it normally (and make sure you use the
// MarshalAs attribute to indicate that you are marshaling an ANSI string).

//
// .method public static pinvokeimpl("msvcrt.dll" cdecl)
//     vararg int32 sscanf(string,int8*) cil managed preservesig { }

// glibc can be found here on Linux: /usr/lib/x86_64-linux-gnu/libc.so.6
// .method public static pinvokeimpl("libc.so.6" cdecl)
//     vararg int32 sscanf(string,int8*) cil managed preservesig { }
