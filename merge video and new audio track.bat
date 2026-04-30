@echo off
if "%~2"=="" (
    echo Drag VIDEO then AUDIO.
    pause
    exit /b
)

ffmpeg -i "%~1" -i "%~2" -c:v copy -c:a aac -map 0:v -map 0:a -map 1:a "%~dp1merged_output.mp4"

echo Done!
pause