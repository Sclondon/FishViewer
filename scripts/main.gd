extends Node3D
## Fish Viewer: pick any kind of Gulp's sea life from the list and it swims about open blue water
## over sand. Drag to turn the camera round, pinch (or the mouse wheel) to zoom. Each kind is loaded
## only when it is picked (its creature's script, baked meshes and paint).
##
## Test flags (after --): --add=a,b,c adds those kinds at the start; --shot=<png> saves a picture
## after a few seconds and quits; --quit-after-secs=<n>.

const MAX_SWIMMERS := 12
const KINDS_PATH := "res://data/kinds.json"

var kinds: Array = []
var swimmers: Array[Swimmer] = []

var _camera: Camera3D
var _yaw := 0.6
var _pitch := -0.25
var _zoom := 1.0
var _room := 3.0
var _floor_y := -2.0
var _floor: MeshInstance3D
var _sand: ShaderMaterial
var _surface: MeshInstance3D
var _water: ShaderMaterial
var _shafts: Array[MeshInstance3D] = []
var _surface_y := 4.0
var _env: Environment
var _clock := 0.0
var _touches := {}
var _pinch_from := 0.0
var _zoom_from := 1.0

var _list_panel: PanelContainer
var _list_button: Button
var _title: Label
var _args := {}


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		var parts := a.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	# (on the web, ?add=a,b in the page's address does the same as --add)
	if OS.has_feature("web"):
		var query := str(JavaScriptBridge.eval("location.search", true))
		for pair in query.trim_prefix("?").split("&", false):
			var kv := pair.split("=", true, 1)
			if kv[0] == "add" and kv.size() > 1:
				_args["add"] = kv[1].uri_decode()
	var text := FileAccess.get_file_as_string(KINDS_PATH)
	kinds = JSON.parse_string(text)
	_build_world()
	_build_ui()
	if _args.has("add"):
		for k: String in String(_args.add).split(","):
			add_kind(k)
	if _args.has("nolist"):
		_toggle_list()
	_fit_room()
	if _args.has("shot"):
		_take_shot.call_deferred(String(_args.shot), float(_args.get("wait", "4")))
	elif _args.has("quit-after-secs"):
		get_tree().create_timer(float(_args["quit-after-secs"])).timeout.connect(get_tree().quit)


func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.05, 0.32, 0.5)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.55, 0.75, 0.85)
	_env.ambient_light_energy = 0.8
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_light_color = Color(0.05, 0.32, 0.5)
	_env.fog_depth_begin = 4.0
	_env.fog_depth_end = 30.0
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62.0, 25.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.1
	add_child(sun)
	# The sand (Gulp's sand picture, low dunes, the light's net drifting over it) and, overhead, the
	# water's surface seen from below: two small shaders of our own (shaders/seabed, shaders/surface).
	var caustics: Texture2D = preload("res://textures/caustics.png")
	_floor = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.0, 1.0)
	plane.subdivide_width = 96
	plane.subdivide_depth = 96
	_floor.mesh = plane
	_sand = ShaderMaterial.new()
	_sand.shader = preload("res://shaders/seabed.gdshader")
	_sand.set_shader_parameter(&"sand_tex", preload("res://textures/sand.png"))
	_sand.set_shader_parameter(&"caustic_tex", caustics)
	_floor.material_override = _sand
	_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_floor)
	_surface = MeshInstance3D.new()
	var top := PlaneMesh.new()
	top.size = Vector2(1.0, 1.0)
	_surface.mesh = top
	_water = ShaderMaterial.new()
	_water.shader = preload("res://shaders/surface.gdshader")
	_water.set_shader_parameter(&"ripple_tex", caustics)
	_surface.material_override = _water
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_surface)
	_build_shafts()
	_camera = Camera3D.new()
	_camera.fov = 60.0
	add_child(_camera)


## A few soft beams of light slanting down from the surface: billboards (turned only about the up axis)
## drawn additively with Godot's standard material and a little fade picture made here.
func _build_shafts() -> void:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 32:
			var side := sin(PI * (x + 0.5) / 32.0)
			var down := 1.0 - (y + 0.5) / 64.0
			var v := side * side * down * down
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	var tex := ImageTexture.create_from_image(img)
	var quad := QuadMesh.new()
	for i in 5:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.disable_fog = true
		m.billboard_keep_scale = true
		m.albedo_texture = tex
		m.albedo_color = Color(0.75, 0.95, 1.0, 0.15)
		var sh := MeshInstance3D.new()
		sh.mesh = quad
		sh.material_override = m
		sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sh)
		_shafts.append(sh)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var big := 44
	_title = Label.new()
	_title.text = "Pick a fish below"
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.2))
	_title.add_theme_constant_override("outline_size", 8)
	_title.position = Vector2(24, 28)
	root.add_child(_title)

	# Top right: clear, and show or hide the list.
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.position = Vector2(-260, 16)
	bar.size = Vector2(244, 110)
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_theme_constant_override("separation", 16)
	root.add_child(bar)
	_list_button = _round_button("-", big)
	_list_button.pressed.connect(_toggle_list)
	bar.add_child(_list_button)
	var clear := _round_button("×", big)
	clear.pressed.connect(clear_all)
	bar.add_child(clear)

	# The list: every kind, under its group, in a scrolling panel over the bottom of the screen.
	_list_panel = PanelContainer.new()
	_list_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_list_panel.anchor_top = 0.58
	_list_panel.offset_top = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.1, 0.16, 0.82)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_list_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_list_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_panel.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)
	var group := ""
	var grid: GridContainer
	for k: Dictionary in kinds:
		if k.group != group:
			group = k.group
			var head := Label.new()
			head.text = group
			head.add_theme_font_size_override("font_size", 26)
			head.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
			col.add_child(head)
			grid = GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 8)
			grid.add_theme_constant_override("v_separation", 8)
			col.add_child(grid)
		var b := Button.new()
		b.text = k.name
		b.custom_minimum_size = Vector2(0, 84)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(add_kind.bind(String(k.kind)))
		grid.add_child(b)


func _round_button(text: String, font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(104, 104)
	b.add_theme_font_size_override("font_size", font)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.1, 0.16, 0.75)
	s.set_corner_radius_all(52)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	var p := s.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.1, 0.3, 0.42, 0.9)
	b.add_theme_stylebox_override("pressed", p)
	return b


func _toggle_list() -> void:
	_list_panel.visible = not _list_panel.visible
	_list_button.text = "-" if _list_panel.visible else "+"


func kind_of(name: String) -> Dictionary:
	for k: Dictionary in kinds:
		if k.kind == name:
			return k
	return {}


## Adds one of a kind (the oldest goes when there are already MAX_SWIMMERS).
func add_kind(name: String) -> void:
	var k := kind_of(name)
	if k.is_empty():
		push_warning("no such kind: " + name)
		return
	if swimmers.size() >= MAX_SWIMMERS:
		swimmers.pop_front().queue_free()
	var s := Swimmer.new()
	s.setup(k)
	add_child(s)
	swimmers.append(s)
	_title.text = k.name
	_fit_room()
	s.place(_room, _floor_y)


func clear_all() -> void:
	for s in swimmers:
		s.queue_free()
	swimmers.clear()
	_title.text = "Pick a fish below"
	_fit_room()


## Sizes the water to the biggest animal in it, and stands the camera back to suit.
func _fit_room() -> void:
	var biggest := 0.3
	for s in swimmers:
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			biggest = maxf(biggest, s.length)
	_room = clampf(biggest * 1.3, 0.6, 40.0)
	_floor_y = -_room * 0.55
	_floor.position.y = _floor_y
	_floor.scale = Vector3.ONE * _room * 30.0
	_sand.set_shader_parameter(&"tile", _room * 0.8)
	_sand.set_shader_parameter(&"caustic_size", _room * 0.9)
	_surface_y = _room * 2.2
	_surface.position.y = _surface_y
	_surface.scale = Vector3.ONE * _room * 30.0
	_water.set_shader_parameter(&"ripple_size", _room * 1.5)
	for i in _shafts.size():
		var a := TAU * i / _shafts.size() + 0.7
		var r := _room * (1.2 + 0.9 * float(i % 3))
		var sh := _shafts[i]
		sh.position = Vector3(cos(a) * r, (_surface_y + _floor_y) * 0.5, sin(a) * r)
		sh.scale = Vector3(_room * (0.5 + 0.2 * float(i % 2)), _surface_y - _floor_y, 1.0)
	_env.fog_depth_begin = _room * 2.5
	_env.fog_depth_end = _room * 9.0
	_camera.near = clampf(_room * 0.01, 0.01, 0.5)
	_camera.far = _room * 40.0
	for s in swimmers:
		if is_instance_valid(s):
			s.room = _room
			s.floor_y = _floor_y


func _process(delta: float) -> void:
	_clock += delta
	RenderingServer.global_shader_parameter_set(&"water_clock", _clock)
	var dist := _room * 3.2 * _zoom
	var at := Vector3(0.0, _room * 0.05, 0.0)
	var off := Vector3(0, 0, dist).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
	_camera.position = at + off
	if _camera.position.y < _floor_y + 0.2 * _room:
		_camera.position.y = _floor_y + 0.2 * _room
	if _camera.position.y > _surface_y - 0.25 * _room:
		_camera.position.y = _surface_y - 0.25 * _room
	for i in _shafts.size():
		(_shafts[i].material_override as StandardMaterial3D).albedo_color.a = 0.11 + 0.07 * sin(_clock * 0.4 + i * 1.9)
	_camera.look_at(at, Vector3.UP)
	# (with the list open, the water shows above it: the point looked at sits higher on the screen)
	_camera.v_offset = -dist * 0.12 if _list_panel.visible else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			var p: Array = _touches.values()
			_pinch_from = (p[0] as Vector2).distance_to(p[1])
			_zoom_from = _zoom
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var p: Array = _touches.values()
			var now := (p[0] as Vector2).distance_to(p[1])
			if _pinch_from > 1.0 and now > 1.0:
				_zoom = clampf(_zoom_from * _pinch_from / now, 0.25, 4.0)
		else:
			_yaw -= event.relative.x * 0.008
			_pitch = clampf(_pitch - event.relative.y * 0.006, -1.4, 0.5)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom * 0.9, 0.25, 4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom * 1.1, 0.25, 4.0)


func _take_shot(path: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", path)
	get_tree().quit()
