extends Node2D
## Ядро — треугольник в центре экрана.
## Игрок вращает его, подставляя нужную грань под шар.

@onready var visual: Polygon2D = $Visual

var target_angle: float = 0.0

# Цвета граней: 0° — красный, 120° — синий, 240° — зелёный
const SECTOR_COLORS: Dictionary = {
	0: "red",
	120: "blue",
	240: "green"
}

# Углы стыков между гранями (60°, 180°, 300°)
const GAP_ANGLES: Array[float] = [60.0, 180.0, 300.0]

const SECTOR_TOLERANCE: float = 60.0  # погрешность для граней в градусах
const GAP_TOLERANCE: float = 10.0     # погрешность для стыков в градусах
const ROTATION_SPEED: float = 20.0


func _ready() -> void:
	add_to_group("core")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var mouse_pos: Vector2 = get_global_mouse_position()
		target_angle = (mouse_pos - global_position).angle()


func _process(delta: float) -> void:
	rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)


func check_hit(orb_color: String, orb_angle: float) -> void:
	## Проверяет столкновение шара с ядром.
	## orb_angle — глобальный угол шара относительно центра.
	## Приводим угол к локальным координатам ядра.
	var local_angle: float = orb_angle - rotation
	
	# Нормализуем угол в диапазон [0, 360)
	local_angle = fmod(local_angle, TAU)
	if local_angle < 0:
		local_angle += TAU
	
	var local_deg: float = rad_to_deg(local_angle)
	
	var gm: Node = get_node("/root/GameManager")
	
	# --- Логика для Бомбы (чёрный шар) ---
	if orb_color == "black":
		if _is_in_gap(local_deg):
			# Бомба попала в стык — УСПЕХ
			gm.add_score(50)
			_flash_visual(Color.WHITE)
		else:
			# Бомба задела грань — ПРОВАЛ
			gm.take_damage()
			_shake_visual(16.0)  # сильная тряска
		return
	
	# --- Логика для обычного шара ---
	# Определяем, в какой сектор попал шар
	var hit_sector: String = ""
	for sector_deg: int in SECTOR_COLORS.keys():
		var diff: float = abs(local_deg - sector_deg)
		var wrapped_diff: float = minf(diff, 360.0 - diff)
		if wrapped_diff <= SECTOR_TOLERANCE:
			hit_sector = SECTOR_COLORS[sector_deg]
			break
	
	if hit_sector == "":
		# Если не попал ни в один сектор — всё равно урон
		gm.take_damage()
		_shake_visual(8.0)
		return
	
	if hit_sector == orb_color:
		gm.add_score(10)
	else:
		gm.take_damage()
		_shake_visual(8.0)


func _is_in_gap(local_deg: float) -> bool:
	## Проверяет, попадает ли угол в зону стыка между гранями.
	for gap_angle: float in GAP_ANGLES:
		var diff: float = abs(local_deg - gap_angle)
		var wrapped_diff: float = minf(diff, 360.0 - diff)
		if wrapped_diff <= GAP_TOLERANCE:
			return true
	return false


func _shake_visual(amplitude: float) -> void:
	## Эффект тряски при неверном попадании.
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	var original_pos: Vector2 = visual.position
	tween.tween_property(visual, "position", Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude)), 0.05)
	tween.tween_property(visual, "position", original_pos, 0.1)


func _flash_visual(color: Color) -> void:
	## Эффект вспышки при успешном попадании бомбы в стык.
	var original_color: Color = visual.color
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "color", color, 0.05)
	tween.tween_property(visual, "color", original_color, 0.15)
