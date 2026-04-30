@echo off
if "%~2"=="" (
    echo Drag and drop VIDEO first, then AUDIO onto this script.
    pause
    exit /b
)

ffmpeg -i "%~1" -i "%~2" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "%~dp1merged_output.mp4"

echo Done!
pause