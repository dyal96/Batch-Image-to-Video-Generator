@echo off
if "%~2"=="" (
    echo Drag VIDEO then AUDIO.
    pause
    exit /b
)

ffmpeg -stream_loop -1 -i "%~2" -i "%~1" -c:v copy -map 1:v:0 -map 0:a:0 -shortest "%~dp1merged_output.mp4"

echo Done!
pause