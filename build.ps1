#!/usr/bin/env pwsh

# This works (building netstandard2.0 library using ilproj)
#dotnet build src/ILProjNetstandard2Lib/ILProjNetstandard2Lib.ilproj

# This works (consuming the library using csproj)
dotnet run --project src/CSProjNet5App/CSProjNet5App.csproj

# This doesn't work (building net5.0 library using ilproj)
#dotnet build src/ILProjNet5Lib/ILProjNet5Lib.ilproj

# This doesn't work either (building net5.0 console app using standalone ilproj)
#dotnet build src/ILProjNet5App/ILProjNet5App.ilproj
#dotnet run --project src/ILProjNet5App/ILProjNet5App.ilproj
