@echo off
echo Building YScript Language Extension...

echo Compiling TypeScript...
call node_modules\.bin\tsc -b

echo Copying compiled files to correct locations...
if not exist "client\out" mkdir "client\out"
if not exist "server\out" mkdir "server\out"

copy "out\client\src\*" "client\out\" /Y > nul
copy "out\server\src\*" "server\out\" /Y > nul

echo Build complete! Extension ready for testing.
echo Use F5 in VS Code to launch Extension Development Host.
