@echo off
if "%~1"=="" (
    echo Drag and drop a video file onto this script.
    pause
    exit
)

set input=%~1
set output=%~dpn1_stretched_1080p.mp4

ffmpeg -i "%input%" -vf "scale=1920:1080" -c:v libx264 -preset fast -crf 23 -c:a copy "%output%"

echo Done!
pause