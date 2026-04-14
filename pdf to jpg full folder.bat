@echo off
mkdir converted_images
for %%f in (*.pdf) do (
    echo Processing "%%f"...
    magick -density 300 "%%f" -quality 90 "converted_images\%%~nf_%%d.jpg"
)
echo Done!
pause