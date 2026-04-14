@echo off
setlocal
title PDF to JPG Converter (Drag and Drop)

:: Check if a file was actually dropped
if "%~1"=="" (
    echo [ERROR] No files detected. 
    echo Please drag and drop PDF files onto this script icon.
    pause
    exit /b
)

:: Create output directory in the folder where the PDFs are located
:: (Or change this to %~dp0 if you want them saved where the script is)
set "outDir=%~dp1JPG_Converted"
if not exist "%outDir%" mkdir "%outDir%"

echo Converting files...
echo ------------------------------------------

:Loop
if "%~1"=="" goto End
    echo Processing: "%~nx1"
    
    :: The Magick Command
    magick -density 300 "%~1" -background white -alpha remove -alpha off -quality 90 "%outDir%\%~n1.jpg"
    
shift
goto Loop

:End
echo ------------------------------------------
echo Done! Files are in: "%outDir%"
pause