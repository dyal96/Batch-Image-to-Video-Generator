@echo off
if "%~2"=="" (
    echo Drag and drop TWO video files onto this script.
    pause
    exit /b
)

ffmpeg -i "%~1" -i "%~2" ^
-filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[outv][outa]" ^
-map "[outv]" -map "[outa]" "%~dp1merged_output.mp4"

echo Done!
pause