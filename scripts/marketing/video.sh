#!/bin/bash
# Builds GIFs and mp4s from the stills render.mjs just wrote.
# No audio. H.264, yuv420p, faststart. GIFs stay short.
set -euo pipefail
cd "$(dirname "$0")/../.."
FFMPEG="${FFMPEG:-ffmpeg}"
WORK=marketing/social/.work
FRAMES=marketing/media/.frames
mkdir -p "$WORK" site/public/media marketing/media marketing/social

gif() {
  local name="$1" fps="$2" width="$3"
  local src="$FRAMES/$name"
  local palette="$WORK/${name}-palette.png"
  "$FFMPEG" -y -v error -framerate "$fps" -i "$src/%03d.png" \
    -vf "fps=${fps},scale=${width}:-1:flags=lanczos,palettegen=max_colors=96:stats_mode=diff" \
    "$palette"
  "$FFMPEG" -y -v error -framerate "$fps" -i "$src/%03d.png" -i "$palette" \
    -lavfi "fps=${fps},scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
    -loop 0 "marketing/media/${name}.gif"
  ls -la "marketing/media/${name}.gif"
}

gif menu-bar 10 800
gif notch-reset 10 1000
gif notch-warning 8 1000
gif history 10 720
gif install 10 880

# Crossfade a list of stills into an H.264 mp4. Args: out w h seconds-per-still files...
xfade_video() {
  local out="$1" w="$2" h="$3" hold="$4"
  shift 4
  local files=("$@")
  local n=${#files[@]}
  local fade=0.45
  local inputs=()
  local i
  for i in "${!files[@]}"; do
    inputs+=(-loop 1 -framerate 30 -t "$(python3 -c "print(${hold} + ${fade})")")
    inputs+=(-i "${files[$i]}")
  done
  local frames
  frames="$(python3 -c "print(int(float('${hold}') * 30))")"
  local fc=""
  for i in "${!files[@]}"; do
    fc+="[${i}:v]scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},zoompan=z='min(1.04,1.0+0.045*on/${frames})':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${w}x${h}:fps=30,format=yuv420p,setsar=1[v${i}];"
  done
  local prev="v0"
  local offset
  offset="$(python3 -c "print(round(${hold} - ${fade} / 2, 3))")"
  # Each extra clip starts after `hold` seconds of the previous, minus the fade overlap once.
  local acc
  acc="$(python3 -c "print(round(${hold}, 3))")"
  for ((i = 1; i < n; i++)); do
    local name="x${i}"
    fc+="[${prev}][v${i}]xfade=transition=fade:duration=${fade}:offset=${acc}[${name}];"
    prev="$name"
    acc="$(python3 -c "print(round(${acc} + ${hold}, 3))")"
  done
  fc+="[${prev}]format=yuv420p[v]"
  "$FFMPEG" -y -v error "${inputs[@]}" -filter_complex "$fc" -map "[v]" \
    -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p -movflags +faststart -an -r 30 \
    "$out"
  ls -la "$out"
  ffprobe -v error -show_entries format=duration:stream=width,height,codec_name -of default=nw=1 "$out"
}

# Reel: the six stories, short, no audio (add music in the app).
xfade_video marketing/social/reel.mp4 1080 1920 2.15 \
  marketing/social/story-01.png \
  marketing/social/story-02.png \
  marketing/social/story-03.png \
  marketing/social/story-04.png \
  marketing/social/story-05.png \
  marketing/social/story-06.png

# Square loop from the four square stills.
xfade_video marketing/social/refill-square-1080.mp4 1080 1080 2.4 \
  "$WORK/sq-01.png" "$WORK/sq-02.png" "$WORK/sq-03.png" "$WORK/sq-04.png"

# Landing-page hero: menu, then the notch, no caption.
xfade_video site/public/media/hero.mp4 1600 1000 2.6 \
  "$WORK/hero-a.png" "$WORK/hero-b.png" "$WORK/hero-c.png"

"$FFMPEG" -y -v error -i "$WORK/hero-b.png" -q:v 3 site/public/media/hero-poster.jpg
ls -la site/public/media/hero-poster.jpg
