#!/usr/bin/env pwsh

# This works (building netstandard2.0 library using ilproj)
#dotnet build src/ILProjNetstandard2Lib/ILProjNetstandard2Lib.ilproj

# This works (consuming the library using csproj)
dotnet run --project src/CSProjNet5App/CSProjNet5App.csproj

# This works (building net5.0 library using ilproj)
# NOTE: <ProduceReferenceAssembly>false</ProduceReferenceAssembly>
#dotnet build src/ILProjNet5Lib/ILProjNet5Lib.ilproj

# This works (building net5.0 console app using standalone ilproj)
# NOTE: <ProduceReferenceAssembly>false</ProduceReferenceAssembly>
dotnet run --project src/ILProjNet5App/ILProjNet5App.ilproj
