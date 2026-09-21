#!/bin/zsh
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
kit_dir="$(cd -- "$script_dir/.." && pwd)"
artifact_dir="$kit_dir/artifacts"
source_image="$artifact_dir/matrix-rain-source.png"
video="$artifact_dir/matrix-rain-animated-2560x1664-hevc.mp4"
still="$artifact_dir/matrix-rain-matching-still-2560x1664.png"
scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/matrix-wallpaper.XXXXXX")"
base="$scratch_dir/base-2560x1664.png"

trap 'rm -rf "$scratch_dir"' EXIT

for tool in ffmpeg ffprobe awk; do
  command -v "$tool" >/dev/null || {
    print -u2 "Missing required tool: $tool"
    exit 1
  }
done

[[ -f "$source_image" ]] || {
  print -u2 "Missing source image: $source_image"
  exit 1
}

ffmpeg -hide_banner -loglevel error -y -i "$source_image" \
  -vf "scale=2560:1664:force_original_aspect_ratio=increase,crop=2560:1664,format=rgb24" \
  -frames:v 1 "$base"

# Every band completes an integer number of passes in 540 frames. The loop
# boundary is therefore exact. Negative scroll values produce top-to-bottom
# motion in FFmpeg's scroll filter.
filter="[0:v]format=gbrp,split=13[bg][s0][s1][s2][s3][s4][s5][s6][s7][s8][s9][s10][s11];"
filter+="[bg]eq=brightness=-0.055:saturation=0.82,gblur=sigma=1.4[canvas];"

widths=(210 190 230 175 220 205 185 240 195 225 205 250)
cycles=(1 2 1 3 2 1 3 2 4 1 3 2)
x=0
previous="canvas"

for i in {0..11}; do
  width=${widths[$((i + 1))]}
  cycle_count=${cycles[$((i + 1))]}
  speed=$(awk -v cycles="$cycle_count" 'BEGIN { printf "%.9f", -cycles/540.0 }')
  filter+="[s${i}]crop=${width}:1664:${x}:0,scroll=v=${speed},eq=brightness=0.015:saturation=1.05[strip${i}];"
  next="overlay${i}"
  filter+="[${previous}][strip${i}]overlay=${x}:0:shortest=1[${next}];"
  previous="$next"
  x=$((x + width))
done

filter+="[${previous}]eq=contrast=1.04:brightness=-0.012:saturation=1.02,format=yuv420p10le[out]"

ffmpeg -hide_banner -loglevel warning -y -loop 1 -framerate 30 -i "$base" \
  -filter_complex "$filter" -map "[out]" -t 18 -r 30 \
  -c:v libx265 -preset fast -crf 20 -tag:v hvc1 \
  -movflags +faststart -an "$video"

# Frame zero is the loop boundary and becomes the static desktop fallback.
ffmpeg -hide_banner -loglevel error -y -i "$video" \
  -vf "select=eq(n\,0),format=rgb24" -frames:v 1 "$still"

"$script_dir/verify-wallpaper.sh"

