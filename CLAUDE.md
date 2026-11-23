# Fish Viewer: notes for future sessions

"Fish Viewer" is a placeholder name (Claude's). The brief (the user, 2026-11-24): "Lets also make a web enabled fish
viewer, so I can have any of the fish options swim around on my phone", then "Add it to the arcade and keep it simple
we're low on tokens". README.md has controls, commands and the web build's size.

## Map

- `scripts/main.gd`: the water (one WorldEnvironment with depth fog, one sun, a sand plane), the camera (drag,
  pinch, wheel), the list UI, adding and clearing.
- `scripts/swimmer.gd` (`Swimmer`): one animal: makes its creature (BakedLook), scales it to the kind's length and
  wanders it, driving its clip as Gulp's `Fish.pose` does (`beat`, `swim`/`sway`, `step`, `curl`).
- `data/kinds.json`: written by `tools/pull_kinds.mjs` from Gulp's species table. Do not hand-edit: change the
  NAMES/GROUPS tables in the tool and run it again.
- `creatures/`, `scripts/baked_look.gd`, `scripts/motion.gd`, `shaders/motion/`: copies (`tools/pull.sh`). Improve
  them in GameCommon/Gulp, not here.

## Decisions (all Claude's picks, 2026-11-24)

- **Gulp's baked creatures as they are.** Animals wear their baked paint and the four motion-family shaders
  (GameCommon baked-look and motion-families), which were made for GL Compatibility in Gulp before it went to
  Forward+, so nothing needed fixing for the web. A few kinds keep their own shader (squids' colour cells, comb
  jelly, anglerfish lure: see baked-look's README), so picking one of those the first time can stall a moment.
- **Open water, not a tank**: background colour + depth fog, a per-vertex-lit sand plane, one sun, no shadows.
  The cheapest scene for phones; no water or light-ray shaders.
- **Decision: one pack.** Every kind is in the one `index.pck` (26.5 MB), but nothing is loaded until picked.
  Alternative: a pack per kind fetched on pick (`ProjectSettings.load_resource_pack`), a smaller start but more
  moving parts; not done because the user asked to keep it simple.
- **Left out** (the coordinator's cut, "keep it simple"): schools, a follow camera, search, icons in the list.
  Each tap adds one animal.

## Things that bite

- After `tools/pull.sh`, run `--headless --import` before any run (new class_names and models).
- `tools/web_excludes.sh` before an export: it leaves the full, primed, school and colony models out of the pack.
