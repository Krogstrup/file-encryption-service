@echo off
rem 7-Zip SendTo wrapper. Place this file in shell:sendto folder.
setlocal enabledelayedexpansion
set scriptDir=%~dp0

echo ===== EncryptWith7Zip %DATE% %TIME% =====
echo Selected: %*

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptDir%EncryptFile.ps1" %*
set rc=!errorlevel!

if !rc! neq 0 (
    echo.
    echo [ERROR] Opdatering mislykkedes ^(exit code !rc!^).
    echo Kontroller 7-Zip installation, filsti og adgangsrettigheder.
) else (
    echo.
    echo [OK] Kryptering fuldført.
)

echo.
echo Tryk en vilkårlig tast for at lukke vinduet...
pause > nul
endlocal
exit /b !rc!

