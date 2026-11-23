class_name Swimmer
extends Node3D
## One animal of a kind (an entry of data/kinds.json) wandering about the water: it picks a point,
## turns towards it and swims there, keeping its own swim clip going (its creature's `step`), as
## Gulp's Fish drives it. Its nose is along -Z; it is scaled to the kind's usual length.

var entry: Dictionary
var length := 1.0
var heading := Vector3.FORWARD
var velocity := Vector3.ZERO
## Half the size of the box it wanders in, and the floor's height.
var room := 3.0
var floor_y := -2.0

var _look: Node3D
var _body: Node3D
var _target := Vector3.ZERO
var _speed := 0.5
var _bend := 0.0
var _beat := 0.0
var _has_swim := false
var _has_sway := false
var _has_walk := false
var _curls := true
var _floor := false
var _still := false


func setup(kind: Dictionary) -> void:
	entry = kind
	length = float(kind.size)
	var script: GDScript = load("res://creatures/%s.gd" % kind.script)
	var look: Node3D = script.new()
	var sets: Dictionary = kind.get("set", {})
	for setting: String in sets:
		look.set(setting, sets[setting])
	BakedLook.apply(look)
	var long: float = float(kind.get("long", 0.0))
	if long <= 0.0:
		long = float(script.get_script_constant_map().get("LENGTH", 1.0))
	var front: float = float(kind.get("front", -1.0))
	if front < 0.0:
		front = long * 0.5
	_body = Node3D.new()
	_body.scale = Vector3.ONE * (length / long)
	add_child(_body)
	look.position = Vector3(0.0, 0.0, front - long * 0.5)
	look.rotation.y = float(kind.get("turn", 0.0))
	_body.add_child(look)
	_look = look
	_beat = float(look.get(&"beat")) if &"beat" in look else 0.0
	_has_swim = &"swim" in look
	_has_sway = &"sway" in look
	_has_walk = &"walk" in look
	_curls = bool(kind.get("curls", true))
	if &"phase" in look:
		look.set(&"phase", randf())
	if &"game" in look:
		look.set(&"game", true)
	for mesh: MeshInstance3D in look.find_children("*", "MeshInstance3D", true, false):
		mesh.lod_bias = 64.0
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_floor = kind.get("how", "swim") == "floor"
	var slow: float = float(kind.get("slow", 1.0))
	_still = slow <= 0.0
	# (Gulp's Fish.pace, halved: a calm wander, not a chase)
	_speed = (2.4 * pow(length, 0.35) + 0.4) * 0.35 * maxf(slow, 0.0)


## Puts it somewhere in the room, facing a random way.
func place(at_room: float, at_floor: float) -> void:
	room = at_room
	floor_y = at_floor
	position = _pick()
	heading = Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized()
	if heading == Vector3.ZERO:
		heading = Vector3.FORWARD
	_target = _pick()
	basis = Basis.looking_at(heading, Vector3.UP)


func _pick() -> Vector3:
	var lift := length * 0.12
	if _floor:
		return Vector3(randf_range(-room, room), floor_y + lift, randf_range(-room * 0.6, room * 0.6))
	var low := floor_y + maxf(length * 0.6, 0.15)
	return Vector3(randf_range(-room, room), randf_range(low, maxf(low, room * 0.7)), randf_range(-room * 0.6, room * 0.6))


func _process(delta: float) -> void:
	if _look == null:
		return
	var turning := 0.0
	if not _still:
		var to := _target - position
		if to.length() < maxf(length, 0.3) or randf() < delta * 0.05:
			_target = _pick()
			to = _target - position
		var want := to.normalized()
		if _floor:
			want.y = 0.0
			want = want.normalized() if want.length() > 0.01 else heading
		var before := heading
		var rate := 1.2 / pow(maxf(length, 0.2), 0.3)
		heading = _turned(heading, want, rate * delta)
		turning = before.signed_angle_to(heading, Vector3.UP) / maxf(delta, 0.0001) / maxf(rate, 0.01)
		velocity = heading * _speed
		position += velocity * delta
		if _floor:
			position.y = floor_y + length * 0.12
		if Vector2(heading.x, heading.z).length() > 0.001:
			basis = Basis.looking_at(heading, Vector3.UP)
	_bend = lerpf(_bend, clampf(turning, -1.0, 1.0), 1.0 - exp(-6.0 * delta))
	var effort := 0.4
	if _beat > 0.0:
		_look.set(&"beat", _beat / (0.55 + 0.6 * effort))
	if _has_swim:
		_look.set(&"swim", 0.3 + 0.35 * effort)
	elif _has_sway:
		_look.set(&"sway", 0.6 + 0.45 * effort)
	if _look.has_method(&"step"):
		_look.call(&"step", velocity if _has_walk else Vector3.ZERO, delta)
	if _curls and _look.has_method(&"set_shader_parameter"):
		_look.call(&"set_shader_parameter", &"curl", _bend * 0.7)


static func _turned(from: Vector3, to: Vector3, most: float) -> Vector3:
	var angle := from.angle_to(to)
	if angle < 0.0001:
		return to
	var axis := from.cross(to)
	if axis.length() < 0.00001:
		axis = Vector3.UP
	return from.rotated(axis.normalized(), minf(angle, most)).normalized()
