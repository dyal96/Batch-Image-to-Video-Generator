@echo off
setlocal EnableDelayedExpansion

:: =====================================================
:: ==== SETTINGS (EDIT THESE DEFAULTS IF NEEDED) =======
:: =====================================================
set duration=5
set fade_duration=1
set fps=24
set bitrate=5000k
set stretch=no          :: yes = stretch to fill, no = fit with padding
set format=mp4          :: default format (mp4 or avi)

:: =====================================================
:: ==== CHOOSE DURATION / FADE INTERACTIVELY ==========
:: =====================================================
echo.
set /p user_duration="Enter image display duration in seconds [default %duration%]: "
if NOT "!user_duration!"=="" set duration=!user_duration!

:ask_fade
set /p user_fade="Enter fade transition duration [default %fade_duration%]: "
if NOT "!user_fade!"=="" set fade_duration=!user_fade!
set /a checkdur=%duration% - %fade_duration%
if !checkdur! LSS 0 (
    echo ⚠️ Fade duration cannot exceed image duration.
    goto ask_fade
)

:: =====================================================
:: ==== CHOOSE STRETCH OR FIT ==========================
:: =====================================================
echo.
echo Image scaling:
echo [1] Fit with black bars (preserve aspect ratio)
echo [2] Stretch to fill (may distort)
set /p stretchChoice="Choose image scaling mode [1 or 2, default 1]: "
if "!stretchChoice!"=="2" (
    set "stretch=yes"
) else (
    set "stretch=no"
)

:: =====================================================
:: ==== CHOOSE VIDEO ORIENTATION =======================
:: =====================================================
:choose_resolution
echo.
echo Select video orientation:
echo [1] Horizontal 16x9 (1920x1080)
echo [2] Vertical   9x16 (1080x1920)
echo [3] Vertical   3x4  (720x960)

set /p resChoice="Enter choice [1, 2, 3]: "
if "%resChoice%"=="1" (
    set "resolution=1920:1080"
    set "resname=16x9_1920x1080"
) else if "%resChoice%"=="2" (
    set "resolution=1080:1920"
    set "resname=9x16_1080x1920"
) else if "%resChoice%"=="3" (
    set "resolution=720:960"
    set "resname=9x12_720x960"
) else (
    echo Invalid choice. Try again.
    goto choose_resolution
)

:: =====================================================
:: ==== CHOOSE OUTPUT FORMAT ===========================
:: =====================================================
echo.
echo Select export format:
echo [1] MP4 (default)
echo [2] AVI
set /p formatChoice="Enter choice (1 or 2): "
if "!formatChoice!"=="2" (
    set "format=avi"
    set "vcodec=libx264"
    set "acodec=pcm_s16le"
) else (
    set "format=mp4"
    set "vcodec=libx264"
    set "acodec=aac"
)

:: =====================================================
:: ==== VALIDATE INPUT FILES ===========================
:: =====================================================
if "%~1"=="" (
    echo Drag and drop image files onto this script.
    pause
    exit /b
)

:: ==== FILE INFO AND OUTPUT DIR ====
set "firstimg=%~f1"
set "firstimgname=%~n1"
set "outputdir=%~dp1Generated Videos"
mkdir "%outputdir%" >nul 2>&1

:: ==== TIMESTAMP OUTPUT NAME ====
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
set outputname=%resname%_%firstimgname%_%yyyy%%mm%%dd%_%hh%%min%.%format%

:: ==== WORKDIR SETUP ====
set "workdir=%TEMP%\fadevideo_%RANDOM%"
mkdir "%workdir%"
set i=0

:: ==== COPY IMAGES ====
for %%F in (%*) do (
    copy "%%~F" "%workdir%\img!i!.jpg" >nul
    set /a i+=1
)
set /a count=i

:: =====================================================
:: ==== CREATE CLIPS ===================================
:: =====================================================
echo.
echo 🎞️ Generating video clips...
cd /d "%workdir%"
set j=0
:generate_clips
if !j! GEQ %count% goto combine_clips

if "!stretch!"=="yes" (
    set "scaling=scale=%resolution%,setsar=1,format=yuv420p"
) else (
    set "scaling=scale=%resolution%:force_original_aspect_ratio=decrease,pad=%resolution%:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,format=yuv420p"
)

"%~dp0ffmpeg.exe" -y -loop 1 -t %duration% -i "img!j!.jpg" -vf "!scaling!" -r %fps% -c:v %vcodec% -b:v %bitrate% -preset veryfast -t %duration% "clip!j!.mp4"
echo Created: clip!j!.mp4
set /a j+=1
goto generate_clips

:: =====================================================
:: ==== COMBINE WITH CROSSFADE =========================
:: =====================================================
:combine_clips
echo.
echo 🔄 Combining clips with crossfade...

set "inputs="
set "filters="
set /a total=%count%-1
for /L %%i in (0,1,%total%) do (
    set "inputs=!inputs! -i clip%%i.mp4"
    set "filters=!filters![%%i:v]scale=%resolution%,setsar=1[v%%i];"
)

:: Build crossfade filter
set "xfades="
set /a offset=%duration% - %fade_duration%
set "prev=v0"
for /L %%i in (1,1,%total%) do (
    set "xfades=!xfades![!prev!][v%%i]xfade=transition=fade:duration=%fade_duration%:offset=!offset![x%%i];"
    set /a offset+=%duration% - %fade_duration%
    set "prev=x%%i"
)

set "filtergraph=!filters!!xfades!"
set "final_map=-map [!prev!]"

:: ==== AUDIO ====
set /a total_duration=(%count% * %duration%) - (%fade_duration% * (%count%-1))

echo.
echo 🔈 Adding silent audio for compatibility...

:: Final FFMPEG command
cmd /V /C ""%~dp0ffmpeg.exe"!inputs! -f lavfi -t %total_duration% -i anullsrc=r=44100:cl=stereo -filter_complex "!filtergraph!" !final_map! -map %count%:a -shortest -r %fps% -c:v %vcodec% -profile:v main -pix_fmt yuv420p -b:v %bitrate% -preset veryfast -c:a %acodec% -movflags +faststart "%outputdir%\%outputname%""


echo.
echo ✅ Done! Output saved to:
echo "%outputdir%\%outputname%"
pause

:: ==== CLEANUP ====
cd /d "%~dp0"
rd /s /q "%workdir%"
