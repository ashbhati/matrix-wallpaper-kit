# Matrix Rain Wallpaper — Build and Deployment Recipe

This kit reproduces and deploys the finished Matrix-style wallpaper used on this Mac. The animation is an 18-second seamless loop of green code rain moving **from top to bottom**, with independent column-band speeds, restrained glow, a deep-black background, and a matching static desktop frame.

## Kit contents

```text
matrix-wallpaper-kit/
├── README.md
├── SHA256SUMS.txt
├── artifacts/
│   ├── matrix-rain-source.png
│   ├── matrix-rain-animated-2560x1664-hevc.mp4
│   └── matrix-rain-matching-still-2560x1664.png
└── scripts/
    ├── build-wallpaper.sh
    └── verify-wallpaper.sh
```

The MP4 and matching still are ready to use. Rebuilding is optional.

## Final media specification

| Property | Value |
|---|---|
| Resolution | 2560 × 1664 pixels |
| Duration | 18.0 seconds |
| Frame rate | 30 fps |
| Frame count | 540 |
| Video codec | HEVC/H.265 |
| Apple codec tag | `hvc1` |
| Pixel format | 10-bit `yuv420p10le` |
| Audio | None |
| Loop | Seamless; each band completes an integer number of passes |
| Motion | Top to bottom |
| Static transition | PNG extracted from frame zero, the loop boundary |

## Visual source

The source PNG was generated with OpenAI's built-in image generator using this production prompt:

> Cinematic Matrix-inspired digital code rain, vertically falling streams of abstract glyphs over a deep pure-black background. Edge-to-edge black with layered columns receding into darkness; elegant restrained density; varied column lengths, brightness, speeds implied by trail lengths, and depth; occasional bright pale-green leading glyphs; subtle bloom and soft atmospheric glow. Near-black, deep emerald, muted phosphor green, and sparse pale mint-white highlights. No readable phrases, Latin words, logos, titles, interface elements, borders, or watermark. Abstract non-semantic glyphs only.

The build first scales and center-crops this source to exactly 2560 × 1664.

## How the animation is built

The source frame is divided into twelve vertical bands. Each band is independently wrapped vertically using FFmpeg's `scroll` filter. The bands complete one to four full passes during the 540-frame sequence, creating parallax and varied apparent speeds.

The key loop calculation is:

```text
normalized speed = -(complete passes / 540 frames)
```

The negative sign is important: with FFmpeg's filter coordinate convention it produces visually downward, top-to-bottom travel. Integer pass counts make the state after frame 540 identical to the state before frame zero, producing a clean loop.

A darkened, gently blurred copy of the source remains underneath the moving bands to preserve depth. The final image receives restrained contrast, brightness, and saturation adjustments before conversion to 10-bit HEVC.

## Build requirements

- macOS
- FFmpeg with `libx265` support
- Standard macOS tools: `zsh`, `awk`, `sips`, `shasum`

With Homebrew, FFmpeg can be installed using:

```sh
brew install ffmpeg
```

## Rebuild

From the kit directory:

```sh
chmod +x scripts/build-wallpaper.sh scripts/verify-wallpaper.sh
./scripts/build-wallpaper.sh
```

The build overwrites the final MP4 and PNG inside `artifacts/`, then runs the verification suite. Rendering takes roughly one minute on the Mac used for the original build.

## Verify without rebuilding

```sh
./scripts/verify-wallpaper.sh
```

The verifier checks codec, Apple-compatible `hvc1` tag, resolution, frame rate, frame count, duration, full-file decoding, and the still-image dimensions.

## Deploy on macOS

### 1. Install the static fallback

1. Open **System Settings → Wallpaper**.
2. Under **Your Photos**, choose **Add Photo → Choose File**.
3. Select `artifacts/matrix-rain-matching-still-2560x1664.png`.
4. Choose **Fill Screen**.
5. Enable **Show on all Spaces** if desired.

This leaves a visually matched frame underneath the live layer whenever animation is paused or stopped.

### 2. Install Waraq

The tested deployment uses **Waraq 1.0.0**, a signed and Apple-notarized open-source live-wallpaper app:

- Project: <https://github.com/bahamut42/waraq>
- Releases: <https://github.com/bahamut42/waraq/releases>

Download the current signed/notarized DMG from the official release page, verify Gatekeeper acceptance, and place `Waraq.app` in `/Applications` or `~/Applications`.

Optional verification before opening:

```sh
codesign --verify --deep --strict --verbose=2 /path/to/Waraq.app
spctl -a -vv --type execute /path/to/Waraq.app
```

Expected Gatekeeper result: `accepted`, with `source=Notarized Developer ID`.

### 3. Import and activate the animation

1. Open Waraq and complete its setup wizard.
2. Open **Waraq Settings → Library**.
3. Choose **Import → From files…**.
4. Select `artifacts/matrix-rain-animated-2560x1664-hevc.mp4`.
5. Open **Displays → Configure** for the target display.
6. Select the imported `matrix-rain-animated-2560x1664-hevc` video.
7. Choose **Fill Screen**.
8. Enable **Loop** and **Muted**.
9. Click **Done** and confirm the display reads **LIVE**.
10. Under **General**, enable **Launch Waraq at login**.

Recommended power settings are **Pause when an app goes fullscreen** and **Pause in Low Power Mode**. Continuous video playback uses more energy than a static wallpaper.

## Tested operational configuration

- Waraq installed in `~/Applications/Waraq.app`
- Custom video imported into Waraq's local wallpaper library
- Main display assignment enabled and reported as `LIVE`
- Fit mode: Fill Screen
- Loop: enabled
- Audio: muted
- Launch at login: enabled
- Full-screen pause: enabled
- Low Power Mode pause: enabled
- macOS static fallback: matching frame-zero PNG

## Troubleshooting

### Rain moves upward

In `build-wallpaper.sh`, keep the scroll calculation negative:

```sh
speed=$(awk -v cycles="$cycle_count" 'BEGIN { printf "%.9f", -cycles/540.0 }')
```

Positive values make the apparent motion run bottom to top.

### Video does not appear

- Confirm the target display is enabled and reads **LIVE** in Waraq.
- Re-select the imported video under **Displays → Configure**.
- Confirm **Loop** is enabled.
- Quit and reopen Waraq after replacing the underlying video file.

### Video appears cropped

The supplied asset is 2560 × 1664. On a display with a different aspect ratio, **Fill Screen** intentionally crops the edges. Choose a fit mode in Waraq if full-frame visibility is more important than edge-to-edge coverage.

### Restore a static desktop

Turn off **Run wallpaper on this display** in Waraq or quit Waraq. The matching PNG remains configured as the underlying macOS wallpaper.

## Safety and portability notes

- The deployment does not modify Apple's private wallpaper catalog.
- Waraq stores an imported copy in the current user's Application Support folder.
- The original MP4 in this kit can be archived independently of Waraq.
- Reinstalling or replacing Waraq does not require rebuilding the media.
- Verify future Waraq releases before running them; do not bypass Gatekeeper for an unsigned build.

