#!/bin/sh
# Sets the Web preset's exclude list (after Gulp's tools/web_excludes.sh): the viewer shows every animal by its
# game model drawn from its baked meshes, so a creature's full model (beside a _game one), the models its baked
# look stands in for (baked/primed.txt) and the school/colony models (never shown here) stay out of the pack.
#   sh tools/web_excludes.sh   (from the project folder, before exporting)
set -e
list="tools/*,tests/*,*.md,creatures/*/example.gd"
for primed in creatures/*/baked/*primed.txt; do
	[ -f "$primed" ] || continue
	for model in $(tr -d '\r' < "$primed"); do
		list="$list,$model"
	done
done
for game in creatures/*/models/*_game.glb; do
	full="${game%_game.glb}.glb"
	[ -f "$full" ] && list="$list,$full"
done
list="$list,creatures/*/models/*_school.glb,creatures/*/models/*_colony.glb"
perl -pi -e 'BEGIN { $l = shift } s/^exclude_filter=.*/exclude_filter="$l"/' "$list" export_presets.cfg
echo "web excludes: $(echo "$list" | tr ',' '\n' | wc -l) paths"
