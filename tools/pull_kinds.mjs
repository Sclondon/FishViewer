// Pulls the sea life in from Gulp: reads Gulp's one table of kinds (scripts/species.gd) and writes
// data/kinds.json (name, group, the creature script, its settings, length as built, size), then prints
// the creature folders those kinds need, one per line, for tools/pull.sh to copy.
//   node tools/pull_kinds.mjs [path to Gulp]
// The creature components are GameCommon's (C:\Projects\GameCommon\godot\<name>); Gulp's copies carry
// the same files plus their imports, so they are taken from Gulp.
import fs from "fs";
import path from "path";

const gulp = process.argv[2] || "C:/Projects/FrontRangeInstituteGames/Gulp";
const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, "$1"));
const src = fs.readFileSync(path.join(gulp, "scripts/species.gd"), "utf8");
const body = src.slice(src.indexOf("const ALL := {"));

// The groups follow the order of Gulp's table; each comment there that starts a section starts a
// group here (the labels are Claude's short names for them).
const GROUPS = [
	["The player's own fish", "Ocean fish"],
	["The estuary's fish", "Rivers"],
	["The kelp forest", "Kelp forest"],
	["The coral reef", "Coral reef"],
	["The sand flats", "Sand flats"],
	["What walks on the bottom", "On the bottom"],
	["The open ocean", "Open ocean"],
	["(the user, 2026-11-18: \"ther eshould be mermaids", "Myths"],
	["(the user, 2026-11-18: \"skeleton ghost", "Ghosts and beasts"],
	["The river mouth", "Fresh water"],
	["The trench: what lives", "Deep sea"],
	["The two deep places", "Vents and whale fall"],
	["What breathes air", "Air breathers"],
	["Marine reptiles", "Sea reptiles"],
	["Arctic animals", "Arctic and rays"],
	["More of the user's second list", "Turtles, stars and shells"],
	["The trench's glowing", "Glowing deep"],
	["The giants", "Giants"],
	["Sea monsters", "Monsters"],
];
// Left out: the old code-built shark (no creature), the submarine (not an animal).
// Where Gulp goes back to an earlier section without a comment.
const RESUME = { wahoo: "Open ocean" };
// Clearer names for Gulp's short keys (Claude's).
const NAMES = { smolt: "Salmon smolt", golden: "Golden trout", tuna: "Yellowfin tuna", loach: "Clown loach", catfish: "Channel catfish", sea_bass: "Giant sea bass", eel: "Moray eel", octopus: "Giant octopus", threadfin: "Threadfin butterfly", raccoon: "Raccoon butterfly", copperband: "Copperband butterfly", longnose: "Longnose butterfly", emperor: "Emperor angelfish", queen: "Queen angelfish", french: "French angelfish", cleaner: "Cleaner wrasse", convict: "Convict tang", halibut: "Halibut", crab: "Rock crab", prawn: "Spot prawn", lobster: "Spiny lobster", mackerel: "Mackerel", flying: "Flying fish", mahi: "Mahi-mahi", bigeye: "Bigeye tuna", bluefin: "Bluefin tuna", humboldt: "Humboldt squid", marlin: "Blue marlin", giant: "Giant squid", pike: "Northern pike", perch: "Yellow perch", koi_sanke: "Koi sanke", koi_showa: "Koi showa", koi_ogon: "Koi ogon", betta_red: "Red betta", betta_marble: "Marble betta", guppy_female: "Guppy female", guppy_red: "Red guppy", guppy_blue: "Blue guppy", guppy_cobra: "Cobra guppy", goldfish_fantail: "Fantail goldfish", corydoras_panda: "Panda cory", platy_wagtail: "Wagtail platy", platy_blue: "Blue platy", gulper: "Gulper eel", otter: "Sea otter", seal: "Harbor seal", devil_ray: "Devil ray", eagle_ray: "Eagle ray", manta: "Manta ray", humpback: "Humpback whale" };
const SKIP = new Set(["shark", "submarine"]);

let group = "Ocean fish";
const kinds = [];
const folders = new Set();
for (const raw of body.split(/\r?\n/)) {
	const line = raw.trim();
	if (line.startsWith("#")) {
		const text = line.replace(/^#\s*/, "");
		for (const [start, label] of GROUPS) if (text.startsWith(start)) group = label;
		continue;
	}
	const m = line.match(/^"([a-z_]+)":\s*(\{.*\}),?$/);
	if (m && RESUME[m[1]]) group = RESUME[m[1]];
	if (!m || SKIP.has(m[1])) continue;
	const e = JSON.parse(m[2]);
	if (!e.script) continue;
	const size = e.size || [1, 1];
	kinds.push({
		kind: m[1],
		name: NAMES[m[1]] || m[1].replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase()),
		group,
		script: e.script,
		set: e.set || {},
		long: e.long || 0,
		front: e.front ?? -1,
		turn: e.turn || 0,
		curls: e.curls ?? true,
		how: e.how || "swim",
		slow: e.slow ?? 1,
		social: e.social || "",
		size: (size[0] + size[1]) / 2,
	});
	folders.add(e.script.split("/")[0]);
}
fs.mkdirSync(path.join(here, "../data"), { recursive: true });
fs.writeFileSync(path.join(here, "../data/kinds.json"), JSON.stringify(kinds, null, "\t") + "\n");
console.error(`kinds: ${kinds.length}, creature folders: ${folders.size}`);
console.log([...folders].join("\n"));
