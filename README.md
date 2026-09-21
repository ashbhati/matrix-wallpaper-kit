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

## Deploy on macOS, including the Lock Screen

The final deployment uses **Phosphene 1.7**, a signed and Apple-notarized open-source app that registers a native macOS wallpaper provider. This lets macOS use the video through its own Wallpaper and Lock Screen pipeline instead of placing a separate animation window behind the desktop.

- Project: <https://github.com/kageroumado/phosphene>
- Releases: <https://github.com/kageroumado/phosphene/releases>

Download the current signed/notarized DMG from the official release page, verify Gatekeeper acceptance, and place `Phosphene.app` in `/Applications` or `~/Applications`.

Optional verification before opening:

```sh
codesign --verify --deep --strict --verbose=2 /path/to/Phosphene.app
spctl -a -vv --type execute /path/to/Phosphene.app
```

Expected Gatekeeper result: `accepted`, with `source=Notarized Developer ID`.

### Import and activate the animation

1. Open Phosphene.
2. Choose **Add Video** and select `artifacts/matrix-rain-animated-2560x1664-hevc.mp4`.
3. In Phosphene's library, select the imported video and choose **Use as Wallpaper…**.
4. In **System Settings → Wallpaper**, find **Phosphene — Video Wallpapers**.
5. Select **Matrix Rain Animated 2560x1664 Hevc**.
6. Leave **Show on all Spaces** enabled if desired.

The selection is applied system-wide through Phosphene's `com.apple.wallpaper` extension. The same native choice supplies the desktop and the animated Lock Screen transition; no separate live-wallpaper layer or login item is required.

The matching PNG remains useful as a portable static fallback but should not be selected while the native video wallpaper is active.

## Tested operational configuration

- Phosphene 1.7 installed in `~/Applications/Phosphene.app`
- Custom HEVC video imported into Phosphene's extension container
- **Matrix Rain Animated 2560x1664 Hevc** selected in System Settings
- macOS wallpaper provider: `glass.kagerou.phosphene.extension`
- Desktop options report **Animated video wallpaper**
- **Show on all Spaces** enabled
- Matching frame-zero PNG retained in the kit as a static fallback

## Troubleshooting

### Rain moves upward

In `build-wallpaper.sh`, keep the scroll calculation negative:

```sh
speed=$(awk -v cycles="$cycle_count" 'BEGIN { printf "%.9f", -cycles/540.0 }')
```

Positive values make the apparent motion run bottom to top.

### Video does not appear

- Open Phosphene's library and confirm the imported video appears.
- In System Settings, confirm the **Phosphene — Video Wallpapers** section appears.
- Re-select the Matrix item in that section.
- If the provider is missing, quit and reopen Phosphene, then reopen Wallpaper settings.

### Video appears cropped

The supplied asset is 2560 × 1664. On a display with a different aspect ratio, macOS may crop the edges to fill the screen.

### Restore a static desktop

In **System Settings → Wallpaper**, select `matrix-rain-matching-still-2560x1664.png` under **Your Photos**.

## Safety and portability notes

- The deployment does not replace or modify an Apple Aerial asset.
- Phosphene stores an imported copy in its sandboxed wallpaper-extension container.
- The original MP4 in this kit can be archived independently of Phosphene.
- Reinstalling or replacing Phosphene does not require rebuilding the media.
- Verify future Phosphene releases before running them; do not bypass Gatekeeper for an unsigned build.
