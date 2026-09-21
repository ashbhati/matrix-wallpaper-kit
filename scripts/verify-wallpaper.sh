#!/bin/zsh
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
kit_dir="$(cd -- "$script_dir/.." && pwd)"
artifact_dir="$kit_dir/artifacts"
video="$artifact_dir/matrix-rain-animated-2560x1664-hevc.mp4"
still="$artifact_dir/matrix-rain-matching-still-2560x1664.png"

command -v ffmpeg >/dev/null || { print -u2 "Missing ffmpeg"; exit 1; }
command -v ffprobe >/dev/null || { print -u2 "Missing ffprobe"; exit 1; }

metadata=$(ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=codec_name,codec_tag_string,width,height,pix_fmt,r_frame_rate,nb_read_frames:format=duration \
  -of default=noprint_wrappers=1 "$video")

for expected in \
  "codec_name=hevc" \
  "codec_tag_string=hvc1" \
  "width=2560" \
  "height=1664" \
  "r_frame_rate=30/1" \
  "nb_read_frames=540" \
  "duration=18.000000"; do
  print -r -- "$metadata" | grep -qx "$expected" || {
    print -u2 "Verification failed: expected $expected"
    exit 1
  }
done

ffmpeg -v error -i "$video" -f null -

dimensions=$(sips -g pixelWidth -g pixelHeight "$still")
print -r -- "$dimensions" | grep -q "pixelWidth: 2560" || exit 1
print -r -- "$dimensions" | grep -q "pixelHeight: 1664" || exit 1

print "Verified: HEVC/hvc1, 2560x1664, 30 fps, 540 frames, 18 seconds, complete decode, matching still dimensions."

