@echo off
setlocal EnableDelayedExpansion

:: ==== DEFAULT SETTINGS ====
set duration=5
set fade_duration=1
set fps=25
set stretch=false
set crossfade=true

:: ==== USER OPTIONS ====
echo Select video orientation:
echo [1] Horizontal (1920x1080)
echo [2] Vertical   (1080x1920)
set /p resChoice="Enter choice [1 or 2]: "
if "%resChoice%"=="1" (
    set "resolution=1920:1080"
) else if "%resChoice%"=="2" (
    set "resolution=1080:1920"
) else (
    echo Invalid choice. Exiting.
    pause
    exit /b
)

:: Fit or stretch
set /p fitChoice="Stretch to fill frame? [y/N]: "
if /I "%fitChoice%"=="y" (
    set stretch=true
)

:: Crossfade
set /p fadeChoice="Add crossfade between images? [Y/n]: "
if /I "%fadeChoice%"=="n" (
    set crossfade=false
)

:: Duration per frame
set /p inputDur="Duration per image (in seconds, default 5): "
if not "%inputDur%"=="" set duration=%inputDur%

:: FPS setting
set /p inputFps="Frames per second (default 25): "
if not "%inputFps%"=="" set fps=%inputFps%

:: ==== VALIDATE INPUT FILES ====
if "%~1"=="" (
    echo Drag and drop images onto this script to create a video.
    pause
    exit /b
)

:: ==== SETUP WORKDIR ====
set "workdir=%TEMP%\fadevideo_%RANDOM%"
mkdir "%workdir%"
set i=0

:: ==== COPY IMAGES ====
for %%F in (%*) do (
    copy "%%~F" "%workdir%\img!i!.jpg" >nul
    set /a i+=1
)
set /a count=i

:: ==== TIMESTAMPED OUTPUT FILENAME ====
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
    set mm=%%a
    set dd=%%b
    set yyyy=%%c
)
for /f "tokens=1-2 delims=:." %%x in ("%time%") do (
    set hh=%%x
    set min=%%y
)
set hh=%hh: =0%
set outputname=video_%yyyy%%mm%%dd%_%hh%%min%.mp4
set "outdir=%~dp0Generated Videos"
if not exist "%outdir%" mkdir "%outdir%"

:: ==== GENERATE VIDEO CLIPS ====
echo.
echo 🎞️ Generating video clips...
cd /d "%workdir%"
set j=0
:generate_clips
if !j! GEQ %count% goto combine_clips

if "%stretch%"=="true" (
    set "filter=scale=%resolution%,setsar=1,format=yuv420p"
) else (
    set "filter=scale=%resolution%:force_original_aspect_ratio=decrease,pad=%resolution%:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,format=yuv420p"
)

"%~dp0ffmpeg.exe" -y -loop 1 -t %duration% -i "img!j!.jpg" -vf "!filter!" -r %fps% -c:v libx264 -preset veryfast -t %duration% "clip!j!.mp4"
if exist "clip!j!.mp4" (
    echo ✅ Created: clip!j!.mp4
) else (
    echo ⚠️ Failed to create clip!j!.mp4 — skipping.
)
set /a j+=1
goto generate_clips

:combine_clips
echo.
if "%crossfade%"=="false" (
    echo 🔗 Concatenating clips without transitions...

    :: Create concat list
    > list.txt (
        for /L %%k in (0,1,%count%) do if exist "clip%%k.mp4" echo file 'clip%%k.mp4'
    )

    "%~dp0ffmpeg.exe" -y -f concat -safe 0 -i list.txt -c:v libx264 -preset veryfast -r %fps% "%outdir%\%outputname%"
    goto done
)

echo 🔄 Combining clips with crossfade transitions...

:: BUILD FILTERS
set "filter="
set "inputs="
set /a total=%count%-1

for /L %%i in (0,1,%total%) do (
    set "inputs=!inputs! -i clip%%i.mp4"
    set "filter=!filter![%%i:v]scale=%resolution%,setsar=1[v%%i]; "
)

set "xfades="
set /a offset=%duration% - %fade_duration%
set "prev=v0"
for /L %%i in (1,1,%total%) do (
    set "xfades=!xfades![!prev!][v%%i]xfade=transition=fade:duration=%fade_duration%:offset=!offset![x%%i]; "
    set /a offset+=%duration% - %fade_duration%
    set "prev=x%%i"
)

set "filtergraph=%filter%%xfades%"
set "final_map=-map [!prev!]"

:: OUTPUT WITH FADE
cmd /V /C ""%~dp0ffmpeg"!inputs! -filter_complex "!filtergraph!" !final_map! -r %fps% -c:v libx264 -preset veryfast -movflags +faststart "%outdir%\%outputname%""

:done
echo.
echo ✅ Video created: "%outdir%\%outputname%"
pause

:: CLEANUP
cd /d "%~dp0"
rd /s /q "%workdir%"
