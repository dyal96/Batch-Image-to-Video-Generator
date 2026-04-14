@echo off
if "%~1"=="" exit /b

set "outDir=%~dp1JPG_Converted"
if not exist "%outDir%" mkdir "%outDir%"

:Loop
if "%~1"== "" goto :EOF
magick -density 300 "%~1" -background white -alpha remove -alpha off -quality 90 "%outDir%\%~n1.jpg"
shift
goto Loop