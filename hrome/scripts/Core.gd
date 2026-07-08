extends Node2D
## Ядро — шестиугольник (3 цвета + 3 стыка).
## Шары уничтожаются при касании сектора (через area_entered).
## Тип сектора определяет результат (цвет/стык).

@onready var visual: Node2D = $Visual

const HIT_EFFECT: PackedScene = preload("res://scenes/HitEffect.tscn")

var target_angle: float = 0.0
const ROTATION_SPEED: float = 20.0

var audio: Node

## Тип каждого сектора по имени узла Area2D.
const SECTOR_TYPES: Dictionary = {
	"RedSector": "red",
	"BlueSector": "blue",
	"GreenSector": "green",
	"Gap1": "gap",
	"Gap2": "gap",
	"Gap3": "gap"
}


func _ready() -> void:
	add_to_group("core")
	audio = get_node("/root/AudioManager")

	# Подключаем сигналы столкновения на каждом секторе-области.
	var hex: Node = visual.get_node_or_null("HexVisual")
	if hex != null:
		for sector: Node in hex.get_children():
			if sector is Area2D:
				sector.area_entered.connect(_on_sector_area_entered.bind(sector.name))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var mouse_pos: Vector2 = get_global_mouse_position()
		target_angle = (mouse_pos - global_position).angle()


func _process(delta: float) -> void:
	rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)


func _on_sector_area_entered(orb: Area2D, sector_name: String) -> void:
	if orb == null or not orb.is_in_group("orb"):
		return
	if orb.has_collided:
		return
	orb.has_collided = true

	var sector_type: String = SECTOR_TYPES.get(sector_name, "")
	_resolve_hit(orb.orb_color, sector_type, orb.global_position)

	orb.queue_free()


func _resolve_hit(orb_color: String, sector_type: String, pos: Vector2) -> void:
	var gm: Node = get_node("/root/GameManager")

	# 1. СТЫК (серый сектор)
	if sector_type == "gap":
		if orb_color == "black":
			gm.add_score(50)
			_flash_visual(Color.WHITE)
			_spawn_hit_effect(pos, Color.WHITE)
			audio.play_sfx("gap")
		else:
			_spawn_hit_effect(pos, _orb_color_to_color(orb_color))
			audio.play_sfx("gap")
		return

	# 2. ЦВЕТНАЯ грань
	if orb_color == "black":
		gm.take_damage()
		_shake_visual(16.0)
		_spawn_hit_effect(pos, Color.RED)
		audio.play_sfx("damage")
	elif sector_type == orb_color:
		gm.add_score(10)
		_spawn_hit_effect(pos, _orb_color_to_color(orb_color))
		audio.play_sfx("absorb")
	else:
		gm.take_damage()
		_shake_visual(8.0)
		_spawn_hit_effect(pos, Color.RED)
		audio.play_sfx("damage")


func _orb_color_to_color(color_name: String) -> Color:
	match color_name:
		"red":
			return Color.RED
		"blue":
			return Color.BLUE
		"green":
			return Color.GREEN
		_:
			return Color.WHITE


func _spawn_hit_effect(pos: Vector2, color: Color) -> void:
	var effect: Node2D = HIT_EFFECT.instantiate()
	get_tree().root.add_child(effect)
	effect.global_position = pos
	effect.z_index = 100
	effect.set_color(color)


func _shake_visual(amplitude: float) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	var original_pos: Vector2 = visual.position
	tween.tween_property(visual, "position", Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude)), 0.05)
	tween.tween_property(visual, "position", original_pos, 0.1)


func _flash_visual(color: Color) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	visual.modulate = color
	tween.tween_property(visual, "modulate", Color.WHITE, 0.15)
