@echo off
REM Live Web Slide Viewer - Windows installer (v2)
REM Registers the manifest sitting next to this script with PowerPoint. A copy
REM into the Wef folder alone is not enough on Windows: PowerPoint lists a
REM sideloaded add-in only when the Developer registry key names the file.
REM Re-run any time to update. Needs no administrator rights.

setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
set "MANIFEST=%SCRIPT_DIR%manifest.xml"
set "WEF_DIR=%LOCALAPPDATA%\Microsoft\Office\16.0\Wef"
set "REG_KEY=HKCU\Software\Microsoft\Office\16.0\WEF\Developer"
set "TARGET=live-web-slide-viewer.xml"
set "ADDIN_ID=94f1f1ac-8278-4a33-8989-5739d7e5452a"

if not exist "%MANIFEST%" (
    echo.
    echo   ERROR: manifest.xml not found.
    echo   Keep this script in the same folder as manifest.xml.
    echo.
    pause
    exit /b 1
)

if not exist "%WEF_DIR%" mkdir "%WEF_DIR%"

REM Earlier installs registered the same add-in under other file names
REM (manifest.xml, or a RoomSum-era copy). Two manifests with one id make
REM PowerPoint list the add-in twice, so drop any file carrying this id.
for %%f in ("%WEF_DIR%\*.xml") do (
    findstr /m /c:"%ADDIN_ID%" "%%f" >nul 2>&1 && (
        reg delete "%REG_KEY%" /v "%%~nxf" /f >nul 2>&1
        del /q "%%f"
    )
)

copy /y "%MANIFEST%" "%WEF_DIR%\%TARGET%" >nul
reg add "%REG_KEY%" /v "%TARGET%" /t REG_SZ /d "%WEF_DIR%\%TARGET%" /f >nul

echo.
echo   Live Web Slide Viewer installed.
echo.
echo   Next steps:
echo     1. Close PowerPoint completely
echo     2. Reopen PowerPoint
echo     3. Insert ^> Add-ins ^> My Add-ins ^> Live Web Slide Viewer
echo.
pause
