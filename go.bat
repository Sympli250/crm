@echo off
echo === LutecIA Build Script v4.0 (With Checks) ===

echo Checking for .NET SDK...
dotnet --version >nul 2>&1
if errorlevel 1 (
    echo Error: .NET SDK not found.
    echo Please install .NET from https://dotnet.microsoft.com/download
    pause
    exit /b 1
)
echo .NET SDK detected.

echo Clearing NuGet caches (pour forcer une nouvelle resolution)...
dotnet nuget locals all --clear

echo Deleting bin and obj folders...
if exist bin rd /s /q bin
if exist obj rd /s /q obj

echo Restoring packages...
dotnet restore LutecIA.csproj
if errorlevel 1 (
    echo Error during restore.
    pause
    exit /b 1
)

echo Building project (verification preliminaire)...
dotnet build LutecIA.csproj --verbosity minimal
if errorlevel 1 (
    echo Error during build verification.
    pause
    exit /b 1
)

echo Cleaning previous build...
dotnet clean LutecIA.csproj

echo Building project (Release)...
dotnet build LutecIA.csproj -c Release
if errorlevel 1 (
    echo Error during build.
    pause
    exit /b 1
)

echo Publishing to publish\app...
dotnet publish LutecIA.csproj -c Release -o publish\app
if errorlevel 1 (
    echo Error during publish.
    pause
    exit /b 1
)

echo.
echo Build completed successfully. Check the publish\app folder.
pause
