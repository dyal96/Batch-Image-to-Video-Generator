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

mkdir "%~dp1Proxy Files" 2>nul
set "output=%~dp1Proxy Files\%filename%_proxy_360p.mp4"

echo Generating 360p Proxy for: %filename%
echo Output: %output%
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

echo [CPU] No GPU encoder found - using libx264.

:encode
echo.

:: ── Encode Proxy ────────────────────────────────────────────────
if "%GPU_TYPE%"=="nvidia" (
    echo Encoding 360p Proxy with NVIDIA NVENC...
    ffmpeg -y -i "%input%" -vf "scale=-2:360,format=yuv420p" -c:v h264_nvenc -preset p2 -cq 28 -c:a aac -b:a 128k "%output%"
) else if "%GPU_TYPE%"=="amd" (
    echo Encoding 360p Proxy with AMD AMF...
    ffmpeg -y -i "%input%" -vf "scale=-2:360,format=yuv420p" -c:v h264_amf -quality speed -qp_i 28 -qp_p 28 -c:a aac -b:a 128k "%output%"
) else if "%GPU_TYPE%"=="intel" (
    echo Encoding 360p Proxy with Intel QSV...
    ffmpeg -y -i "%input%" -vf "scale=-2:360,format=yuv420p" -c:v h264_qsv -preset fast -q:v 28 -c:a aac -b:a 128k "%output%"
) else (
    echo Encoding 360p Proxy with CPU...
    ffmpeg -y -i "%input%" -vf "scale=-2:360" -c:v libx264 -preset veryfast -crf 28 -c:a aac -b:a 128k "%output%"
)

echo.
echo Done!
pause
