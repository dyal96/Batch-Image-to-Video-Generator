@echo off
setlocal EnableDelayedExpansion

:: ==== SETTINGS ====
set duration=5
set fade_duration=1
set fps=24

:: ==== CHOOSE ORIENTATION ====
:choose_resolution
echo Select video orientation:
echo [1] Horizontal (1920x1080)
echo [2] Vertical   (1080x1920)
set /p resChoice="Enter choice [1 or 2]: "
if "%resChoice%"=="1" (
    set "resolution=1920:1080"
) else if "%resChoice%"=="2" (
    set "resolution=1080:1920"
) else (
    echo Invalid choice. Try again.
    goto choose_resolution
)

:: ==== VALIDATE INPUT FILES ====
if "%~1"=="" (
    echo Drag and drop images onto this file to generate a video.
    pause
    exit /b
)

:: ==== SETUP TEMP FOLDER ====
set "workdir=%TEMP%\fadevideo_%RANDOM%"
mkdir "%workdir%"
set i=0

:: ==== COPY IMAGES TO TEMP FOLDER ====
for %%F in (%*) do (
    copy "%%~F" "%workdir%\img!i!.jpg" >nul
    set /a i+=1
)
set /a count=i

:: ==== GENERATE OUTPUT FILENAME WITH TIMESTAMP ====
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
  set mm=%%a
  set dd=%%b
  set yyyy=%%c
)
for /f "tokens=1-2 delims=:." %%x in ("%time%") do (
  set hh=%%x
  set min=%%y
)
:: Remove spaces if any in hh
set hh=%hh: =0%
set outputname=video_%yyyy%%mm%%dd%_%hh%%min%.mp4

:: ==== CREATE VIDEO CLIPS FROM IMAGES ====
echo Generating video clips...
cd /d "%workdir%"
set j=0
:generate_clips
if !j! GEQ %count% goto combine_clips

"%~dp0ffmpeg.exe" -y -loop 1 -t %duration% -i "img!j!.jpg" -vf "scale=%resolution%:force_original_aspect_ratio=decrease,pad=%resolution%:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,format=yuv420p" -r %fps% -c:v libx264 -preset veryfast -t %duration% "clip!j!.mp4"
if exist "clip!j!.mp4" (
    echo Created: clip!j!.mp4
) else (
    echo ⚠️ Failed to create clip!j!.mp4 — skipping.
)
set /a j+=1
goto generate_clips

:combine_clips
echo Combining with crossfade transitions...

:: BUILD FILTER COMPLEX STRING
set "filter="
set "inputs="
set /a total=%count%-1

for /L %%i in (0,1,%total%) do (
    set "inputs=!inputs! -i clip%%i.mp4"
    set "filter=!filter![%%i:v]scale=%resolution%,setsar=1[v%%i]; "
)

:: CHAIN WITH XFADE
set "xfades="
set /a offset=%duration% - %fade_duration%
set "prev=v0"
for /L %%i in (1,1,%total%) do (
    set "xfades=!xfades![!prev!][v%%i]xfade=transition=fade:duration=%fade_duration%:offset=!offset![x%%i]; "
    set /a offset+=%duration% - %fade_duration%
    set "prev=x%%i"
)

:: FINAL FILTERGRAPH + OUTPUT
set "filtergraph=%filter%%xfades%"
set "final_map=-map [!prev!]"

echo.
echo 🛠️ Generating output video...
cmd /V /C ""%~dp0ffmpeg.exe"!inputs! -filter_complex "!filtergraph!" !final_map! -r %fps% -c:v libx264 -preset veryfast -movflags +faststart "%~dp0%outputname%""

echo.
echo ✅ Done! Output saved as: %outputname%
pause

:: CLEANUP
cd /d "%~dp0"
rd /s /q "%workdir%"
