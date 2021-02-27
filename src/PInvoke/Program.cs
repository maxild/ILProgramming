using System;
using System.Text;
using System.Runtime.InteropServices;

// # Compile on Linux with:
// $ dotnet /usr/share/dotnet/sdk/5.0.103/Roslyn/bincore/csc.dll \
//     -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Runtime.dll \
//     -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Console.dll \
//     -reference:/usr/share/dotnet/packs/Microsoft.NETCore.App.Ref/5.0.0/ref/net5.0/System.Runtime.InteropServices.dll \
//     -out:Program.dll Program.cs

public static class Program
{
    // C glibc function with variable arguments ...
    //    int sscanf (const char *str, const char *format, ...);
    // This function reads data from "str", splits it up using "format"
    // and then stores the results in the locations pointed to by the
    // remaining arguments (the "...") which are variable in both number and type.
    // Therefore sscanf("%d", "112", varargs ) is eqivalent to int.Parse()

    // Attempt 1: Unhandled exception. System.Runtime.InteropServices.MarshalDirectiveException: Cannot marshal 'parameter #3': Signature is not Interop compatible.
    // [DllImport("libc.so.6", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
    // static extern int sscanf(string str, string format, params object[] varargs);

    // Attempt 2: It works!!!
    // [DllImport("libc.so.6", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
    // static extern int sscanf(string str, string format,
    //     out int arg1, out char arg2, out int arg3, out char arg4, StringBuilder arg5);

    // Attempt 3: Unhandled exception. System.InvalidProgramException: Vararg calling convention not supported.
    // [DllImport("libc.so.6", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
    // static extern int sscanf(string str, string format, __arglist);
    // NOTE
    //    The problem with __arglist is that it is painfully slow. But that is
    //    the official mechanism in .NET for supporting variable arguments.
    //    It really only exists for the purposes of supporting varargs methods via P/Invoke.

    // Simplified with no vararg, and single int arg
    [DllImport("libc.so.6", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
    static extern int sscanf(string str, string format, out int arg1);

    public static void Main()
    {
        //string str = "1 + 2 = three";
        //string format = "%d %c %d %c %s"; // int, char, int, char, string

        // Attempt 1:
        // object[] varargs = new object[5];
        // int result = sscanf(str, format, varargs);
        // for (int i = 0; i < result; i++)
        //     Console.WriteLine(varargs[i]);

        // Attempt 2
        // int arg1, arg3;
        // char arg2, arg4;
        // var arg5 = new StringBuilder(5); // need a buffer big enough to return the string
        // int result = sscanf(str, format, out arg1, out arg2, out arg3, out arg4, arg5);
        // Console.WriteLine("{0} {1} {2} {3} {4}", arg1, arg2, arg3, arg4, arg5);

        // Attempt 3:
        // int arg1=default, arg3=default;
        // char arg2=default, arg4=default;
        // var arg5 = new StringBuilder(5); // need a buffer big enough to return the string
        // int result = sscanf(str, format, __arglist(ref arg1, ref arg2, ref arg3, ref arg4, arg5));
        // Console.WriteLine("{0} {1} {2} {3} {4}", arg1, arg2, arg3, arg4, arg5);

        // str = "one + 2 = 3";
        // format = "%s %c %d %c %d"; // string, char, int, char, int
        // result = sscanf(str, format, __arglist(arg5, out arg2, out arg1, out arg4, out arg3));
        // Console.WriteLine("{0} {1} {2} {3} {4}", arg5, arg2, arg1, arg4, arg3);
        // Console.ReadKey();

        // This will show us (via ildasm) how to p/invoke using IL
        string s = "123";
        string format = "%d"; // int
        int result;
        int c = sscanf(s, format, out result);
        Console.WriteLine("Result = {0}", result);

        Console.ReadKey();
    }
}
