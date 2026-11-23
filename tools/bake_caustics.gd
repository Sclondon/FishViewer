extends SceneTree
## Bakes textures/caustics.png, the net of light the waves throw down: the same picture Gulp's
## `Sea.caustic_texture()` makes at its start (9 x 9 jittered cells over 256 pixels, tiling), baked once
## here so a phone does not work it out. Run once from the project folder:
##   godot --headless --audio-driver Dummy --path . -s tools/bake_caustics.gd

const CELLS := 9
const SIZE := 256


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var points := PackedVector2Array()
	for j in CELLS:
		for i in CELLS:
			points.append(Vector2(i + rng.randf_range(0.15, 0.85), j + rng.randf_range(0.15, 0.85)))
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5) * CELLS / SIZE
			var ci := int(p.x)
			var cj := int(p.y)
			var f1 := 9.0
			var f2 := 9.0
			for dj in range(-2, 3):
				for di in range(-2, 3):
					var ii := posmod(ci + di, CELLS)
					var jj := posmod(cj + dj, CELLS)
					var q := points[jj * CELLS + ii] + Vector2(ci + di - ii, cj + dj - jj)
					var d := p.distance_to(q)
					if d < f1:
						f2 = f1
						f1 = d
					elif d < f2:
						f2 = d
			var edge := 1.0 - smoothstep(0.02, 0.3, f2 - f1)
			var glow := 1.0 - smoothstep(0.0, 0.7, f2 - f1)
			var v := clampf(edge * 0.8 + glow * 0.3, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	img.save_png("res://textures/caustics.png")
	print("baked textures/caustics.png")
	quit()
