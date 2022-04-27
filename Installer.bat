@echo off
set quiet=YES
REM Checking if we have access to system as administrator.
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM Checking the error while trying to access.
if '%errorlevel%' EQU '0' (
    goto SkipRunAs
)

REM The same bat file will get executed by the script with elevated rights.
echo Getting administrator privilege for uninstalling service.
if not "%quiet%" == "YES" timeout /T 3
"%~dp0scripts\admin_request.vbs" "%~s0"
exit /B

:SkipRunAs
powershell -ExecutionPolicy ByPass -File "%~dp0scripts\Helper.ps1"