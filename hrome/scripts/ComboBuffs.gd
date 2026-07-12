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
		var old := core.get_node_or_null("ComboShield")
		if old:
			old.queue_free()

	var shield := Sprite2D.new()
	shield.name = "ComboShield"
	shield.texture = preload("res://assets/orb.png")
	shield.scale = Vector2(3, 3)
	shield.modulate = Color(0.3, 0.6, 1.0, 0.4)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	shield.material = mat
	core.add_child(shield)
	shield_timer.start(SHIELD_DURATION)


func _on_shield_end() -> void:
	var shield := get_node_or_null("/root/GameManager/../Main/Core/ComboShield")
	if shield:
		shield.queue_free()


func is_shield_active() -> bool:
	return shield_timer.time_left > 0


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
	# Орбы продолжают лететь со своими цветами — сброс не нужен
	pass


func activate_shockwave() -> int:
	var points: int = 0
	for orb in get_tree().get_nodes_in_group("orb"):
		points += 1
		orb.queue_free()
	return points * 10
