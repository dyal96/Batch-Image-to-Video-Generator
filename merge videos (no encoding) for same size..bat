@echo off
if "%~2"=="" (
    echo Drag and drop TWO video files onto this script.
    pause
    exit /b
)

echo file '%~1' > list.txt
echo file '%~2' >> list.txt

ffmpeg -f concat -safe 0 -i list.txt -c copy "%~dp1merged_output.mp4"

del list.txt

echo Done!
pause