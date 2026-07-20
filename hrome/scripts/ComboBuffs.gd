extends Node
## Автономные баффы комбо: slowmo, monochrome, shield, shockwave.

const SLOWMO_DURATION: float = 5.0
const MONOCHROME_DURATION: float = 10.0
const SHIELD_DURATION: float = 10.0

var shield_timer: Timer
var slowmo_timer: Timer
var monochrome_timer: Timer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	shield_timer = Timer.new()
	shield_timer.name = "ShieldTimer"
	shield_timer.one_shot = true
	shield_timer.timeout.connect(_on_shield_end)
	add_child(shield_timer)

	slowmo_timer = Timer.new()
	slowmo_timer.name = "SlowmoTimer"
	slowmo_timer.one_shot = true
	slowmo_timer.timeout.connect(_on_slowmo_end)
	add_child(slowmo_timer)

	monochrome_timer = Timer.new()
	monochrome_timer.name = "MonochromeTimer"
	monochrome_timer.one_shot = true
	monochrome_timer.timeout.connect(_on_monochrome_end)
	add_child(monochrome_timer)


func activate_shield(core: Node2D) -> void:
	if shield_timer.time_left > 0:
		shield_timer.stop()

	# Включаем ShieldArea (нода уже есть в Core.tscn)
	var shield_area: Area2D = core.get_node("ShieldArea")
	if shield_area and shield_area.has_method("set_active"):
		shield_area.set_active(true)

	shield_timer.start(SHIELD_DURATION)


func _on_shield_end() -> void:
	var shield_area := get_node_or_null("/root/GameManager/../Main/Core/ShieldArea")
	if shield_area and shield_area.has_method("set_active"):
		shield_area.set_active(false)


func is_shield_active() -> bool:
	var shield_area := get_node_or_null("/root/GameManager/../Main/Core/ShieldArea")
	if shield_area:
		return shield_area.shield_active
	return false


func activate_slowmo() -> void:
	if slowmo_timer.time_left > 0:
		slowmo_timer.stop()

	for orb in get_tree().get_nodes_in_group("orb"):
		if orb.has_method("set_speed_mult"):
			orb.set_speed_mult(0.4)

	slowmo_timer.start(SLOWMO_DURATION)


func _on_slowmo_end() -> void:
	for orb in get_tree().get_nodes_in_group("orb"):
		if orb.has_method("set_speed_mult"):
			orb.set_speed_mult(1.0)


func activate_monochrome(target_color: String) -> void:
	if monochrome_timer.time_left > 0:
		monochrome_timer.stop()

	var gm := get_node("/root/GameManager")
	for orb in get_tree().get_nodes_in_group("orb"):
		if orb.has_method("_orb_color_to_color"):
			orb.orb_color = target_color
			var c = orb._orb_color_to_color(target_color)
			orb.visual.modulate = c

	monochrome_timer.start(MONOCHROME_DURATION)


func _on_monochrome_end() -> void:
	pass


func activate_shockwave() -> int:
	var points: int = 0
	for orb in get_tree().get_nodes_in_group("orb"):
		points += 1
		orb.queue_free()
	return points * 10
