extends SceneTree
## Prints how a few kinds swim over 20 s (speed, effort, beat, swim size, curl), to check the tail beat
## follows the speed and the body bends into its turns:
##   godot --headless --audio-driver Dummy --path . -s tests/swim_probe.gd

func _initialize() -> void:
	var kinds: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/kinds.json"))
	for want in ["sardine", "leopard_shark", "eel"]:
		for k: Dictionary in kinds:
			if k.kind != want:
				continue
			var s := Swimmer.new()
			root.add_child(s)
			s.setup(k)
			s.place(3.0, -2.0)
			var look: Node3D = s.get("_look")
			var line := ""
			for i in 400:
				s._process(0.05)
				if i % 40 == 0:
					line += "  v%.2f e%.2f b%.2f s%.2f c%+.2f" % [s.velocity.length(), s.get("_effort"),
						float(look.get(&"beat")) if &"beat" in look else 0.0,
						float(look.get(&"swim")) if &"swim" in look else float(look.get(&"sway")) if &"sway" in look else 0.0,
						s.get("_bend") * 0.7]
			print(want, ":", line)
			s.queue_free()
	quit()
