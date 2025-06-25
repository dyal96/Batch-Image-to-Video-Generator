@echo off
setlocal EnableDelayedExpansion

:: Check if at least one file is dropped
if "%~1"=="" (
    echo Drag and drop image files onto this script.
    pause
    exit /b
)

:: Ask for video orientation
:choose_orientation
echo Select video orientation:
echo [1] Horizontal (1920x1080)
echo [2] Vertical (1080x1920)
set /p orientation="Enter choice [1 or 2]: "
if "%orientation%"=="1" (
    set "scale=scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black"
) else if "%orientation%"=="2" (
    set "scale=scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black"
) else (
    echo Invalid choice. Try again.
    goto choose_orientation
)

:: Ask for duration
set /p duration="Enter duration per image in seconds (e.g. 5): "

:: Prepare temp folder
set "tmpfolder=%TEMP%\imgvideo_%RANDOM%"
mkdir "%tmpfolder%"

:: Copy and rename dropped files
set i=0
for %%F in (%*) do (
    copy "%%~F" "%tmpfolder%\img!i!.jpg" >nul
    set /a i+=1
)

:: Create list.txt
set "listfile=%tmpfolder%\list.txt"
> "%listfile%" (
    for /L %%i in (0,1,!i!) do (
        if exist "%tmpfolder%\img%%i.jpg" (
            echo file 'img%%i.jpg'
            echo duration %duration%
        )
    )
    set /a last=i-1
    echo file 'img!last!.jpg'
)

:: Run ffmpeg
cd /d "%tmpfolder%"
echo.
echo 🛠️ Generating video with ffmpeg (24 FPS)...

"%~dp0ffmpeg.exe" -y -f concat -safe 0 -i list.txt -vf "%scale%,fps=24,format=yuv420p" -r 24 -movflags +faststart "%~dp0output.mp4"

echo.
echo ✅ Done! Video saved as: output.mp4
pause

:: Cleanup
cd /d "%~dp0"
rd /s /q "%tmpfolder%"
