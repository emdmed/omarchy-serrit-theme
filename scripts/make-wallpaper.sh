#!/usr/bin/env bash
# Turn any image into a Serrit wallpaper.
#
#   scripts/make-wallpaper.sh [options] <image>...
#
# Each image is cropped to fill the screen, mapped onto the palette in
# colors.toml (shadows -> slate, highlights -> parchment), then given a dark
# band at the top for the bar, a vignette and light grain.
#
# Options:
#   -o DIR        output directory            (default: backgrounds/)
#   -n NAME       output file name, one input only (default: <input name>.jpg)
#   -s WxH        output size                 (default: 3840x2160)
#   -c PERCENT    original colour kept, 0-100 (default: 30)
#   -b GAMMA      brightness, <1 darker       (default: 1.0)
#   -m AMOUNT     mist: softens contrast, 0 = none (default: 4)
#   -a PERCENT    gold tint in the highlights, 0-100 (default: 35)
#   -t PERCENT    height of the top fade      (default: 20)
#   -v PERCENT    vignette strength, 0-100    (default: 45)
#   -g AMOUNT     grain, 0 turns it off       (default: 0.15)
#   -G GRAVITY    crop anchor: center, north, south... (default: center)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
colors="$root/colors.toml"

outdir="$root/backgrounds"
name=""
size="3840x2160"
keep=30
gamma=1.0
mist=4
gold=35
topfade=20
vignette=45
grain=0.15
gravity=center

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while getopts "o:n:s:c:b:m:a:t:v:g:G:h" opt; do
  case $opt in
    o) outdir=$OPTARG ;;
    n) name=$OPTARG ;;
    s) size=$OPTARG ;;
    c) keep=$OPTARG ;;
    b) gamma=$OPTARG ;;
    m) mist=$OPTARG ;;
    a) gold=$OPTARG ;;
    t) topfade=$OPTARG ;;
    v) vignette=$OPTARG ;;
    g) grain=$OPTARG ;;
    G) gravity=$OPTARG ;;
    h) usage ;;
    *) usage 1 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || usage 1
[ -z "$name" ] || [ $# -eq 1 ] || { echo "-n works with one input only" >&2; exit 1; }
command -v magick >/dev/null || { echo "needs ImageMagick 7 (magick)" >&2; exit 1; }

# Read a colour from colors.toml.
color() {
  local v
  v=$(sed -n "s/^$1 *= *\"\(#[0-9a-fA-F]\{6\}\)\".*/\1/p" "$colors")
  [ -n "$v" ] || { echo "colour '$1' missing from $colors" >&2; exit 1; }
  echo "$v"
}

# Gradient map, dark to light. Stretched into a 256px lookup table below.
stops=(
  "$(color darker_background)"
  "$(color background)"
  "$(color lighter_background)"
  "$(color selection)"
  "$(color muted)"
  "$(color dark_foreground)"
  "$(color light_foreground)"
  "$(color foreground)"
)
shade=$(color darker_background)
accent=$(color accent)

w=${size%x*}
h=${size#*x}
fadeh=$(( h * topfade / 100 ))
vig_edge=$(( 100 - vignette ))
goldf=$(awk -v g="$gold" 'BEGIN { print g / 100 }')
soften=()
[ "$mist" = 0 ] || soften=(+sigmoidal-contrast "${mist}x50%")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

lut="$tmp/lut.png"
args=()
for c in "${stops[@]}"; do args+=("xc:$c"); done
magick "${args[@]}" +append -filter triangle -resize '256x1!' "$lut"

mkdir -p "$outdir"

for src in "$@"; do
  base=$(basename "${src%.*}")
  out="$outdir/${name:-$base.jpg}"

  magick "${src}[0]" -auto-orient -colorspace sRGB \
    -resize "${size}^" -gravity "$gravity" -extent "$size" \
    -write mpr:src +delete \
    \( mpr:src -colorspace gray -auto-level -gamma "$gamma" ${soften[@]+"${soften[@]}"} -write mpr:tone -colorspace sRGB "$lut" -clut -type TrueColor -write mpr:mapped \) \
    \( mpr:mapped \( mpr:src -modulate 100,60 \) -compose colorize -composite \) \
    -compose blend -define compose:args="$keep" -composite \
    \( -size "$size" xc:"$accent" \( mpr:tone -level 50%,95% -evaluate multiply "$goldf" \) \
       -alpha off -compose copyopacity -composite \) \
    -compose over -composite \
    \( -size "${w}x${fadeh}" gradient:"$shade"-"${shade}00" \) \
    -gravity north -compose over -composite \
    \( -size "$size" -define gradient:extent=diagonal radial-gradient:white-black \
       -level -60%,100% +level "${vig_edge}%",100% \) \
    -compose multiply -composite \
    \( -size "$size" xc:gray50 -attenuate "$grain" +noise gaussian -colorspace gray \) \
    -compose softlight -composite \
    -type TrueColor -quality 90 "$out"

  echo "$out"
done
