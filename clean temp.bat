@echo off
echo ====================================
echo   Cleaning TEMP files...
echo ====================================

:: Clear user TEMP folder
echo Deleting files from %TEMP% ...
del /f /s /q "%TEMP%\*.*" >nul 2>&1
for /d %%p in ("%TEMP%\*.*") do rmdir "%%p" /s /q

:: Clear Windows TEMP folder
echo Deleting files from C:\Windows\Temp ...
del /f /s /q "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%p in ("C:\Windows\Temp\*.*") do rmdir "%%p" /s /q

echo ====================================
echo   Done..!
echo ====================================
timeout /t 5 /nobreak >nul

cls
echo ====================================
echo  All TEMP files cleaned successfully!
echo ====================================
pause
