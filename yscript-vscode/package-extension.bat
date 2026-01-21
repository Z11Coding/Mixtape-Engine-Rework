@echo off
echo Packaging YScript VS Code Extension...

echo Installing vsce if not present...
call npm install @vscode/vsce --save-dev

echo Packaging extension...
call npx vsce package --allow-star-activation

echo.
if exist "*.vsix" (
    echo ✅ Success! Extension packaged as .vsix file
    echo.
    echo You can now:
    echo 1. Install locally: Right-click the .vsix file → "Install Extension VSIX"
    echo 2. Share with others: Send them the .vsix file
    echo 3. Install via command line: code --install-extension filename.vsix
    echo.
    dir *.vsix
) else (
    echo ❌ Packaging failed. Check the output above for errors.
)

pause
