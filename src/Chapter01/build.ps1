#!/usr/bin/env pwsh

# compile assembly using ilasm compiler
#   portable pdb
# ../../tools/ilasm.5.0.0/runtimes/linux-x64/native/ilasm /PDBFMT=PORTABLE /DLL /OUTPUT=Program.dll Program.il
../../tools/ilasm.5.0.0/runtimes/linux-x64/native/ilasm Program

# decompile assembly using ildasm decompiler
# NOTE: /out=Simple.ildasm.il doesn't work???!!!???
# ../../tools/ildasm.5.0.0/runtimes/linux-x64/native/ildasm Program.exe > Program.ildasm.il