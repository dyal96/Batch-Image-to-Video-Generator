@echo off
setlocal EnableDelayedExpansion

:: ==== SETTINGS ====
set duration=5
set fade_duration=1
set fps=24
set bitrate=8000k
set jpeg_quality=85

:: ==== PATHS ====
:: Use %~dp0 to refer to the folder where this script is saved
set "script_dir=%~dp0"
set "ffmpeg_exe=%~dp0ffmpeg.exe"
set "caesium_exe=%~dp0caesiumclt.exe"
:: If magick is in your system PATH, leave as is. Otherwise paste full path.
set "magick_exe=magick" 

set "workdir=%~dp0temp_processing_%RANDOM%"

:: ==== CHECK TOOLS ====
if not exist "%ffmpeg_exe%" (
    color 0C
    echo [ERROR] ffmpeg.exe not found in: %script_dir%
    pause
    exit /b
)

set use_caesium=true
if not exist "%caesium_exe%" (
    echo [WARNING] caesiumclt.exe not found. Optimization disabled.
    set use_caesium=false
)

:: ==== RESOLUTION SETUP ====
echo Select video orientation:
echo [1] Horizontal (1920x1080)
echo [2] Vertical   (1080x1920)
set /p resChoice="Enter choice [1 or 2]: "

if "%resChoice%"=="2" (
    set "width=1080"
    set "height=1920"
) else (
    set "width=1920"
    set "height=1080"
)
set "resolution=%width%:%height%"

:: ==== SETUP FOLDERS ====
if not exist "%workdir%" mkdir "%workdir%"
if not exist "%workdir%\raw_caesium" mkdir "%workdir%\raw_caesium"
set "outputdir=%script_dir%Generated_Videos"
if not exist "%outputdir%" mkdir "%outputdir%"

set outputname=Video_%RANDOM%.mp4

:: ==== STEP 1: PROCESS IMAGES & PDFS ====
echo.
echo ---------------------------------------
echo [STEP 1] Processing Assets...
echo ---------------------------------------

set i=0
for %%F in (%*) do (
    set "ext=%%~xF"

    if /I "!ext!"==".pdf" (
        echo [PDF] Processing: %%~nxF
        :: Convert PDF to JPEGs (Requires Ghostscript installed)
        "%magick_exe%" -density 300 "%%~fF" -quality %jpeg_quality% "%workdir%\pdf_page_%%d.jpg"
        
        if exist "%workdir%\pdf_page_*.jpg" (
            for /f "delims=" %%P in ('dir /b /on "%workdir%\pdf_page_*.jpg"') do (
                call :process_single_image "%workdir%\%%P"
            )
            del "%workdir%\pdf_page_*.jpg" >nul
        ) else (
            echo [ERROR] PDF conversion failed. Is Ghostscript installed?
        )
    ) else (
        call :process_single_image "%%~fF"
    )
)

set /a count=i
if %count% EQU 0 (
    echo [ERROR] No images found to process.
    pause
    exit /b
)
goto generate_clips

:: ==== SUBROUTINE: Optimize Images ====
:process_single_image
set "input_full_path=%~1"
set "target_file=%workdir%\img!i!.jpg"
set "processed=false"

echo  -^> Asset !i!

if "!use_caesium!"=="true" (
    :: Clear temp folder to ensure we grab the correct new file
    del /q "%workdir%\raw_caesium\*.*" >nul 2>&1
    
    "%caesium_exe%" -q %jpeg_quality% -o "%workdir%\raw_caesium" --width %width% --height %height% "!input_full_path!" >nul
    
    :: Move whatever file Caesium created to our target name
    if exist "%workdir%\raw_caesium\*.*" (
        move /y "%workdir%\raw_caesium\*.*" "!target_file!" >nul
        if exist "!target_file!" set "processed=true"
    )
)

:: Fallback if Caesium failed or is disabled
if "!processed!"=="false" (
    copy /y "!input_full_path!" "!target_file!" >nul
)

set /a i+=1
exit /b

:: ==== STEP 2: GENERATE CLIPS ====
:generate_clips
echo.
echo ---------------------------------------
echo [STEP 2] Creating Video Clips...
echo ---------------------------------------

set j=0
:clip_loop
if !j! GEQ %count% goto combine_clips

set "clip_in=%workdir%\img!j!.jpg"
set "clip_out=%workdir%\clip!j!.mp4"

:: Validate input exists
if not exist "!clip_in!" (
    echo [ERROR] Missing image file: !clip_in!
    set /a j+=1
    goto clip_loop
)

set "scalefilter=format=rgb24,scale=%resolution%:force_original_aspect_ratio=decrease,pad=%resolution%:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,format=yuv420p"
set /a clip_duration=%duration% + %fade_duration%

"%ffmpeg_exe%" -v error -y -loop 1 -t !clip_duration! -i "!clip_in!" -vf "!scalefilter!" -r %fps% -c:v libx264 -b:v %bitrate% -preset veryfast "!clip_out!"

set /a j+=1
goto clip_loop

:: ==== STEP 3: FINALIZE VIDEO ====
:combine_clips
echo.
echo ---------------------------------------
echo [STEP 3] Finalizing...
echo ---------------------------------------

set "inputs="
set "filters="
set /a total=%count%-1

for /L %%i in (0,1,%total%) do (
    set "inputs=!inputs! -i "%workdir%\clip%%i.mp4""
    set "filters=!filters![%%i:v]scale=%resolution%,setsar=1[v%%i];"
)

:: Build crossfades
set "xfades="
set /a offset=%duration% - %fade_duration%
set "prev=v0"

if %count% GTR 1 (
    for /L %%i in (1,1,%total%) do (
        set "xfades=!xfades![!prev!][v%%i]xfade=transition=fade:duration=%fade_duration%:offset=!offset![x%%i];"
        set /a offset+=%duration%
        set "prev=x%%i"
    )
    set "filtergraph=!filters!!xfades!"
) else (
    set "filtergraph=!filters!"
)

set "final_map=-map [!prev!]"
set /a total_duration=(%count% * %duration%) + %fade_duration%

"%ffmpeg_exe%" -v error -y !inputs! -f lavfi -t %total_duration% -i anullsrc=r=44100:cl=stereo -filter_complex "!filtergraph!" !final_map! -map %count%:a -shortest -r %fps% -c:v libx264 -pix_fmt yuv420p -b:v %bitrate% -preset veryfast -c:a aac -movflags +faststart "%outputdir%\%outputname%"

echo.
echo Done! Video saved to:
echo "%outputdir%\%outputname%"

:: Cleanup
rmdir /s /q "%workdir%"

pause
exit