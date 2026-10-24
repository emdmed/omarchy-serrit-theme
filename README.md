# Serrit

A dark Omarchy theme in twilight slate, parchment and gold leaf. Slate surfaces, warm cream text, a gold accent on borders and the cursor, and muted forest greens and river blues for everything else.

![Serrit preview](preview.png)

## Install

```sh
omarchy theme install https://github.com/emdmed/omarchy-serrit-theme
```

## What's in it

- `colors.toml`: the full palette. Omarchy generates the terminal, Hyprland, Neovim, btop, Chromium and shell colors from it.
- `icons.theme`: Yaru sage icons, which sit well next to the greens.
- A river-valley wallpaper (3840×2160), darkened toward the top so a transparent bar stays readable.

## Make your own wallpaper

`scripts/make-wallpaper.sh` turns any image into a Serrit wallpaper. It crops the image to 3840×2160, maps its tones onto the palette from `colors.toml` (shadows go to slate, highlights to parchment), keeps a little of the original colour, warms the brightest areas with the gold accent, then adds the dark band at the top, a vignette and fine grain. Needs ImageMagick 7.

```sh
scripts/make-wallpaper.sh ~/Pictures/forest.jpg            # -> backgrounds/forest.jpg
scripts/make-wallpaper.sh -n 6-forest.jpg ~/Pictures/forest.jpg
scripts/make-wallpaper.sh -o ~/out ~/Pictures/*.jpg        # batch
```

Tuning: `-c` how much original colour to keep (default 30), `-b` brightness, `-m` mist (lower is punchier), `-a` gold in the highlights (default 35, try 70 for gilded skies), `-t` top fade height, `-v` vignette, `-g` grain, `-G north` to crop from the top. Run with `-h` for the full list. Because the colours come from `colors.toml`, editing the palette changes every wallpaper you regenerate.

## Palette

| Role | Hex | Role | Hex |
|---|---|---|---|
| Background | `#141b1e` | Foreground | `#e8e2d0` |
| Accent | `#dcb662` | Selection | `#2f3d3a` |
| Red | `#e3836f` | Green | `#a6c78e` |
| Yellow | `#dcb662` | Blue | `#7fa7b8` |
| Magenta | `#b99ac2` | Cyan | `#93c3b8` |

## License

[MIT](LICENSE)
