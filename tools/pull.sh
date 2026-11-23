#!/bin/sh
# Pulls every kind of Gulp's sea life into this project (run from the project folder):
#   sh tools/pull.sh [path to Gulp]
# 1. data/kinds.json from Gulp's species table (tools/pull_kinds.mjs);
# 2. each creature folder those kinds use, from Gulp's creatures/ (GameCommon components with their
#    baked paint and motion labels), without their Blender sources (tools/);
# 3. the shared parts that draw them: GameCommon baked-look (scripts/baked_look.gd) and motion-families
#    (scripts/motion.gd, shaders/motion/), the same files in GameCommon and Gulp.
# Then: godot --headless --path . --import, and sh tools/web_excludes.sh before a web export.
# Never edits Gulp. New kinds in Gulp's table come in by running this again.
set -e
gulp=${1:-/c/Projects/FrontRangeInstituteGames/Gulp}
folders=$(node tools/pull_kinds.mjs "$gulp")
mkdir -p creatures scripts shaders
for f in $folders; do
	tar -C "$gulp/creatures" --exclude="$f/tools" -cf - "$f" | tar -C creatures -xf -
done
# Folders the copied ones point at (a shader shared between components).
for f in $(grep -rhoE 'res://creatures/[a-z_]+' creatures | sort -u | sed 's#res://creatures/##'); do
	[ -d "creatures/$f" ] || [ ! -d "$gulp/creatures/$f" ] || { echo "also: $f"; tar -C "$gulp/creatures" --exclude="$f/tools" -cf - "$f" | tar -C creatures -xf -; }
done
cp "$gulp/scripts/baked_look.gd" "$gulp/scripts/motion.gd" scripts/
tar -C "$gulp/shaders" -cf - motion | tar -C shaders -xf -
echo "pulled $(echo "$folders" | wc -l) creature folders from $gulp"
