#!/usr/bin/env pwsh

# version of tooling (roslyn)
$DOTNET_SDK_VERSION='5.0.200'

# package reference version
$NEWTONSOFT_JSON_VERSION ='12.0.3'
$NEWTONSOFT_JSON_TFM='netstandard2.0'

# NOTE: Reference assemblies are distributed with the SDK!!!!

# "reference pack": reference assemblies (aka header files)
# $CORE_REF_LIB = 'System.Runtime.dll'      # This is not the implementation CoreLib!!!!!
# $REF_PACK = 'Microsoft.NETCore.App.Ref'
# $REF_PACK_VERSION='5.0.0'
# $REF_PACK_TFM = 'net5.0'

# "reference pack": reference assemblies (aka header files)
#     Internal implementation package (distributed with the SDK) not meant for
#     direct consumption. Please do not reference directly.
#     A set of standard .NET APIs that are prescribed to be used and supported
#     together. Contains **reference assemblies**, and other design-time assets.
$CORE_REF_LIB = 'netstandard.dll'         # this is the implementation CoreLib!!!!!!
$REF_PACK = 'NETStandard.Library.Ref'
$REF_PACK_VERSION = '2.1.0'
$REF_PACK_TFM = 'netstandard2.1'
# NOTE: In contrast, regular assemblies are called **implementation assemblies**.

# .NET Standard provides the contract assembly, netstandard.dll, that represents
# the set of common APIs shared between different .NET platforms. The implementations
# of these APIs are contained in different assemblies on different platforms,
#     mscorlib.dll on .NET Framework
#     System.Private.CoreLib.dll on .NET Core.
# A library that targets .NET Standard can run on all platforms that support .NET Standard.

# Using the reference assembly ensures you're not taking a dependency on implementation details.

# Reference assemblies for the .NET Framework libraries are distributed with "targeting packs".

# For .NET Core 3.0 and higher, the reference assemblies for the core framework are in the
#     Microsoft.NETCore.App.Ref package (the Microsoft.NETCore.App package is used instead for versions before 3.0).

# For .NET Standard 2.0/2.1, the reference assemblies for the core framework are in the
#     NETStandard.Library.Ref package (the NETStandard.Library package is used instead for versions before 2.0???!!!???).

# Because they contain no implementation, reference assemblies can't be loaded for execution.
# Trying to do so results in a System.BadImageFormatException. If you want to examine the
# contents of a reference assembly, you can load it into the reflection-only context in .NET Framework
# (using the Assembly.ReflectionOnlyLoad method) or into the MetadataLoadContext in .NET Core.

# If you want to distribute reference assemblies with NuGet packages, you must include them
# in the ref\ subdirectory under the package directory instead of in the lib\ subdirectory
# used for implementation assemblies.

# For .NET Core, you can force publish operation to copy reference assemblies for your target
# platform into the publish/refs subdirectory of your output directory by setting the
# "PreserveCompilationContext" project property to true. Then you can pass these reference
# assembly files to the compiler. Using "DependencyContext" from "Microsoft.Extensions.DependencyModel"
# package can help locate their paths.


# NOTE: NewtonSoft.Json was build against netstandard2.0 => CS1701
#    warning CS1701: Assuming assembly reference 'netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' used by 'Newtonsoft.Json' matches identity 'netstandard, Version=2.1.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' of 'netstandard', you may need to supply runtime policy
#    Program.cs(5, 13): warning CS1701: Assuming assembly reference 'netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' used by 'Newtonsoft.Json' matches identity 'netstandard, Version=2.1.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' of 'netstandard', you may need to supply runtime policy

# Bash
#   mkdir -p ./packages/Newtonsoft.Json/12.0.3/
#   curl -L https://www.nuget.org/api/v2/package/Newtonsoft.Json/12.0.3 | tar -xf - -C ./packages/Newtonsoft.Json/12.0.3/

$packagePath = './packages/Newtonsoft.Json/$NEWTONSOFT_JSON_VERSION/'
New-Item -Path $packagePath -ItemType "directory" 2>&1>$null
$packageLibPath = "${packagePath}lib"
if (!(Test-Path $packageLibPath)) {
  # download nupkg as file with zip ext
  $zipFileName = "Newtonsoft.Json.${NEWTONSOFT_JSON_VERSION}.zip"
  Invoke-WebRequest https://www.nuget.org/api/v2/package/Newtonsoft.Json/$NEWTONSOFT_JSON_VERSION `
    -OutFile $zipFileName
  Expand-Archive $zipFileName -D $packagePath
  Remove-Item ./$zipFileName
}
# else {
#   write-host "package is downloaded already"
# }

# Program.dll : Program.cs (make style)
dotnet /usr/share/dotnet/sdk/$DOTNET_SDK_VERSION/Roslyn/bincore/csc.dll `
    -reference:/usr/share/dotnet/packs/$REF_PACK/$REF_PACK_VERSION/ref/$REF_PACK_TFM/$CORE_REF_LIB `
    -reference:/usr/share/dotnet/packs/$REF_PACK/$REF_PACK_VERSION/ref/$REF_PACK_TFM/System.Console.dll `
    -reference:/usr/share/dotnet/packs/$REF_PACK/$REF_PACK_VERSION/ref/$REF_PACK_TFM/System.Collections.dll `
    -reference:./packages/Newtonsoft.Json/$NEWTONSOFT_JSON_VERSION/lib/$NEWTONSOFT_JSON_TFM/Newtonsoft.Json.dll `
    -nowarn:CS1701 `
    -out:Program.dll Program.cs

if ($LASTEXITCODE -ne 0) {
  write-Host "ERROR!!!!!"
  exit $LASTEXITCODE
}

# NOTE: We cannot run the app, because the dunamic loading of the package reference need deps.json
#   Unhandled exception. System.IO.FileNotFoundException: Could not load file or
#   assembly 'Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed'.
#   The system cannot find the file specified.

# Solution 1: Copy to Appbase
# cp ./packages/Newtonsoft.Json/$NEWTONSOFT_JSON_VERSION/lib/$NEWTONSOFT_JSON_TFM/Newtonsoft.Json.dll .

# Solution 2: deps.json (dependency manifest) combined with additional probing paths
# that can be configured 3 ways:

# (i) Program.runtimeconfig.dev.json
# {
#   "runtimeOptions": {
#     "additionalProbingPaths": [
#     "/home/maxfire/.dotnet/store/|arch|/|tfm|",
#     "/home/maxfire/.nuget/packages",
#     "./packages/"    <---- BEST OPTION (relative path supported here)
#     ]
#   }
# }

# (ii) --additionalprobingpath <path>
#           Path containing probing policy and assemblies to probe for.
# dotnet exec --additionalprobingpath ./packages/ Program.dll

# (iii) Program.runtimeconfig.json DOES NOT work!!!!
# {
#   "runtimeOptions": {
#     "tfm": "net5.0",
#     "framework": {
#       "name": "Microsoft.NETCore.App",
#       "version": "5.0.0"
#     }
#   },
#   "additionalProbingPaths": [
#   "./packages/"
#   ]
# }

# run the program
dotnet Program.dll