@echo off
REM
REM Slide Viewer — One-Click Installer for Windows
REM Copies manifest.xml to PowerPoint's add-in folder.
REM After running this, close and reopen PowerPoint.
REM

REM Get the directory where this script lives
set "SCRIPT_DIR=%~dp0"
set "MANIFEST=%SCRIPT_DIR%manifest.xml"

REM PowerPoint's sideload folder
set "WEF_DIR=%LOCALAPPDATA%\Microsoft\Office\16.0\Wef"

REM Check that manifest.xml exists next to this script
if not exist "%MANIFEST%" (
    echo.
    echo   ERROR: manifest.xml not found.
    echo   Make sure this script is in the same folder as manifest.xml.
    echo.
    pause
    exit /b 1
)

REM Create the Wef folder if it doesn't exist
if not exist "%WEF_DIR%" (
    mkdir "%WEF_DIR%"
)

REM Copy the manifest
copy /y "%MANIFEST%" "%WEF_DIR%\" >nul

echo.
echo   Slide Viewer installed successfully!
echo.
echo   Next steps:
echo     1. Close PowerPoint completely
echo     2. Reopen PowerPoint
echo     3. Go to Home ^> Add-ins ^> Slide Viewer
echo.
pause
