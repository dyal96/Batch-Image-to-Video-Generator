@echo off
setlocal enabledelayedexpansion
title Folder Structure Cloner
color 0A

:: -------------------------------------------------------------------------
:: STEP 1: Drag & Drop SOURCE
:: -------------------------------------------------------------------------
cls
echo ========================================================
echo   FOLDER STRUCTURE CLONER
echo ========================================================
echo.
echo 1. Drag and drop the SOURCE folder into this window.
echo    (The one you want to copy FROM)
echo.
set /p "source= > "

:: Remove quotes if Windows added them automatically
set "source=!source:"=!"

if "%source%"=="" goto :Error

:: -------------------------------------------------------------------------
:: STEP 2: Drag & Drop TARGET
:: -------------------------------------------------------------------------
echo.
echo --------------------------------------------------------
echo.
echo 2. Drag and drop the TARGET folder into this window.
echo    (The one you want to copy TO)
echo.
set /p "target= > "

:: Remove quotes if Windows added them automatically
set "target=!target:"=!"

if "%target%"=="" goto :Error

:: -------------------------------------------------------------------------
:: STEP 3: Execute
:: -------------------------------------------------------------------------
echo.
echo --------------------------------------------------------
echo Cloning structure...
echo FROM: "!source!"
echo TO:   "!target!"
echo.

:: /T = Tree (structure only)
:: /E = Empty directories included
xcopy "!source!" "!target!" /T /E >nul

echo.
echo ========================================================
echo SUCCESS! All folders cloned.
echo ========================================================
echo.
pause
exit

:Error
echo.
echo You did not provide a valid folder path.
echo.
pause