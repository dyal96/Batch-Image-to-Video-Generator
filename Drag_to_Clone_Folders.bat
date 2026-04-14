@echo off
setlocal enabledelayedexpansion
title Fast Clone
color 0E

:: Get the folder dropped onto the script icon
set "source=%~1"

:: If no folder was dropped, ask for it manually
if "%source%"=="" (
    cls
    echo ========================================================
    echo   DRAG SOURCE FOLDER HERE OR ONTO THE ICON
    echo ========================================================
    set /p "source= > "
    set "source=!source:"=!"
)

:: Check if source is valid
if not exist "!source!" (
    echo [ERROR] Source "!source!" not found.
    pause
    exit
)

:: Ask for Target
cls
echo SOURCE: "!source!"
echo.
echo --------------------------------------------------------
echo Drag ^& Drop (or Type) the TARGET folder path:
echo (Folder will be created if it doesn't exist)
echo --------------------------------------------------------
set /p "target= > "
set "target=!target:"=!"

:: Create target if it doesn't exist
if not exist "!target!" (
    echo Creating target directory...
    mkdir "!target!" 2>nul
)

:: Execute cloning
echo Cloning structure...
xcopy "!source!" "!target!" /T /E /Y >nul

echo.
echo DONE! Closing...
timeout /t 2 >nul
exit