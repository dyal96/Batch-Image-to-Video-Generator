@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Drag and drop a video file onto this script.
    pause
    exit /b
)

set "input=%~1"
set "filename=%~n1"

echo Input file: %input%
echo.

set /p targetSizeMB=Enter target size (in MB): 

if "%targetSizeMB%"=="" (
    echo Invalid size.
    pause
    exit /b
)

:: Get duration in seconds using ffprobe
for /f "delims=" %%a in ('ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%input%"') do set duration=%%a

:: Remove decimal part (integer only for set /a)
for /f "tokens=1 delims=." %%a in ("%duration%") do set durationSec=%%a

if "%durationSec%"=="" (
    echo Failed to detect duration.
    pause
    exit /b
)

:: Convert MB to bits
set /a targetSizeBits=%targetSizeMB%*8388608

:: Reserve 128 kbps for audio
set /a audioBitrate=128000

:: Calculate video bitrate in bps
set /a videoBitrate=(targetSizeBits/durationSec)-audioBitrate

if %videoBitrate% LEQ 0 (
    echo Target size too small for this video duration.
    pause
    exit /b
)

:: Convert bps to kbps for ffmpeg -b:v flag
set /a videoBitrateK=%videoBitrate%/1000

mkdir "%~dp1Compressed Files" 2>nul
set "output=%~dp1Compressed Files\%filename%_compress_%targetSizeMB%mb.mp4"

echo.
echo Duration     : %durationSec% seconds
echo Video bitrate: %videoBitrate% bps  (%videoBitrateK% kbps)
echo Output       : %output%
echo.

:: ── GPU Detection: NVIDIA → AMD → Intel → CPU ─────────────────
set "GPU_TYPE=cpu"

ffmpeg -hide_banner -f lavfi -i nullsrc -t 0.01 -c:v h264_nvenc -f null - >nul 2>&1
if %errorlevel% equ 0 (
    set "GPU_TYPE=nvidia"
    echo [GPU] NVIDIA NVENC detected - using hardware acceleration.
    goto :encode
)

ffmpeg -hide_banner -f lavfi -i nullsrc -t 0.01 -c:v h264_amf -f null - >nul 2>&1
if %errorlevel% equ 0 (
    set "GPU_TYPE=amd"
    echo [GPU] AMD AMF detected - using hardware acceleration.
    goto :encode
)

ffmpeg -hide_banner -f lavfi -i nullsrc -t 0.01 -c:v h264_qsv -f null - >nul 2>&1
if %errorlevel% equ 0 (
    set "GPU_TYPE=intel"
    echo [GPU] Intel QSV detected - using hardware acceleration.
    goto :encode
)

echo [CPU] No GPU encoder found - using libx264 ^(2-pass^).

:encode
echo.

:: ── Encode ────────────────────────────────────────────────────
if "%GPU_TYPE%"=="nvidia" (
    echo Encoding with NVIDIA NVENC...
    ffmpeg -y -hwaccel cuda -hwaccel_output_format cuda -i "%input%" -c:v h264_nvenc -rc:v vbr -b:v %videoBitrateK%k -maxrate:v %videoBitrateK%k -bufsize:v %videoBitrateK%k -preset p4 -c:a aac -b:a 128k "%output%"
) else if "%GPU_TYPE%"=="amd" (
    echo Encoding with AMD AMF...
    ffmpeg -y -hwaccel d3d11va -i "%input%" -c:v h264_amf -rc cbr -b:v %videoBitrateK%k -maxrate %videoBitrateK%k -bufsize %videoBitrateK%k -quality balanced -c:a aac -b:a 128k "%output%"
) else if "%GPU_TYPE%"=="intel" (
    echo Encoding with Intel QSV...
    ffmpeg -y -hwaccel qsv -i "%input%" -c:v h264_qsv -b:v %videoBitrateK%k -maxrate %videoBitrateK%k -bufsize %videoBitrateK%k -preset medium -c:a aac -b:a 128k "%output%"
) else (
    echo Encoding with CPU ^(2-pass for accurate size^)...
    ffmpeg -y -i "%input%" -c:v libx264 -b:v %videoBitrate% -pass 1 -an -f null NUL
    ffmpeg -y -i "%input%" -c:v libx264 -b:v %videoBitrate% -pass 2 -c:a aac -b:a 128k "%output%"
    del /f /q ffmpeg2pass-0.log ffmpeg2pass-0.log.mbtree 2>nul
)

echo.
echo Done!
pause
