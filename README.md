# Fish Viewer

Live: https://sclondon.github.io/FishViewer/build/index.html (regular arcade cart "Fish Viewer", no scores; after a change: export, push, bump the cart's `?v=` in the site's games.tsx).

Pick any of Gulp's sea life (158 kinds, in 19 groups) and watch it swim about open blue water over sand. Godot 4.7,
GL Compatibility, portrait phone first (works on desktop). Placeholder name. Asked for by the user on 2026-11-24:
"Lets also make a web enabled fish viewer, so I can have any of the fish options swim around on my phone".

## Controls (all on screen)

- **The list** (bottom): tap a name to add one of that kind (up to 12; the oldest goes after that). Scroll it.
- **-/+** (top right): hide or show the list.
- **×** (top right): clear the water.
- **Drag** the water to turn the camera round; **pinch** (or the mouse wheel) to zoom.

The water sizes itself to the biggest animal in it, so a whale and a clownfish together make the clownfish tiny.

## Run and check

```sh
G="/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
"$G" --path .                                                   # play
"$G" --path . --audio-driver Dummy --resolution 360x780 -- --add=garibaldi,manta --shot=out.png   # a still
"$G" --headless --path . --export-release "Web" build/index.html  # web build (run tools/web_excludes.sh first)
node tests/web_check.js <out dir>   # the web build in Chrome at 360x780: stills, load time, console errors
```

Flags after `--`: `--add=a,b` (kinds from data/kinds.json), `--nolist`, `--shot=<png> [--wait=<s>]`,
`--quit-after-secs=<n>`. On the web, `?add=a,b` in the address does the same as `--add`.

## Where the animals come from

`sh tools/pull.sh` reads Gulp's kinds table (`Gulp/scripts/species.gd`) into `data/kinds.json` (`tools/pull_kinds.mjs`;
names and group labels are Claude's) and copies each creature folder it uses from `Gulp/creatures/` (GameCommon
components, the same files, with their baked paint and motion labels; Blender sources left out), plus GameCommon
`baked-look` (`scripts/baked_look.gd`) and `motion-families` (`scripts/motion.gd`, `shaders/motion/`). It never
edits Gulp. Run it again to bring in new kinds, then `godot --headless --path . --import`.

## Web build (2026-11-24)

- Download: `index.pck` 26.5 MB + `index.wasm` 39.5 MB (Godot's engine, about 9 MB gzipped over the wire) +
  small files: 66 MB on disk.
- First picture: 3.5 s in Chrome from a local server (cold profile), 5 s for the page with five kinds added.
  On a phone over the network it is mostly the download.
- Nothing is loaded at the start but the list: a kind's script, meshes and paint are read when it is picked.
  The whole pack is still downloaded up front (see CLAUDE.md, "Decision: one pack").
