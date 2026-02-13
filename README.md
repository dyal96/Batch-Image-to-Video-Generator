## 🎞️ Batch Image to Video Generator — v1.0

### 🔧 Overview

This is a **drag-and-drop batch script** to convert a sequence of images into a smooth, crossfaded video using FFmpeg — with full control over orientation, transitions, fit/stretch mode, frame duration, and frame rate.

No software installation required — just FFmpeg and Windows.
[ffmpeg ](https://www.ffmpeg.org/download.html)
extra compression : [caesium](https://saerasoft.com/caesium/) / [caesiumclt](https://saerasoft.com/caesiumclt/) / [soruce-code](https://github.com/Lymphatus/caesium-clt)
pdf to jpg process:[imagemagick](https://imagemagick.org/#gsc.tab=0) / [Ghostscript](https://ghostscript.com/)

---

### ✨ Features

* ✅ **Drag & Drop Images** — Just drop your images onto the `.bat` file.
* 🖼️ **Choose Orientation** — Horizontal (1920x1080) or Vertical (1080x1920).
* 🔍 **Fit or Stretch** — Choose whether to fit images inside the frame (with black bars) or stretch them to fill completely.
* ⏱️ **Custom Frame Duration** — Choose how many seconds each image stays (default: 5s).
* 🎚️ **Crossfade Option** — Optional smooth fade transitions (default: enabled).
* 🎞️ **Frame Rate Control** — Set FPS for your final video (default: 25 FPS).
* 🗂️ **Organized Output** — Videos are automatically saved in a `Generated Videos` folder with a timestamped filename.

---

### 📦 Requirements

* Windows
* [FFmpeg](https://ffmpeg.org/download.html) — Place `ffmpeg.exe` in the same folder as the `.bat` file.

---

### 🛠️ How to Use

1. 🔽 **Download the ZIP** or clone the repo.
2. 📁 Place `ffmpeg.exe` and `make_video.bat` in the same folder.
3. 🖼️ **Drag and drop images** onto `make_video.bat`.
4. 💬 Answer the prompts (orientation, stretch, fade, etc.).
5. 🎬 Final video will be saved as `Generated Videos\video_YYYYMMDD_HHMM.mp4`.

---

### 📌 Example

```text
Select video orientation:
[1] Horizontal (1920x1080)
[2] Vertical   (1080x1920)
Enter choice [1 or 2]: 1

Stretch to fill frame? [y/N]: n

Add crossfade between images? [Y/n]: y

Duration per image (in seconds, default 5): 4

Frames per second (default 25): 30
```

---

### 📁 Output Sample

```
📂 Generated Videos
└── video_20250627_1642.mp4
```

---

### 🧹 Clean & Lightweight

* All temporary files are stored in `%TEMP%` and deleted after export.
* Pure `.bat` file — no external UI or dependencies beyond FFmpeg.

---

### 📥 Download

[[🔽 Download latest release](https://github.com/dyal96/SlideShow_Video/archive/refs/heads/main.zip)](#) (replace with actual GitHub release zip/link)

---

Let me know if you'd like a logo/icon or GitHub Actions automation to zip the release and upload it.
