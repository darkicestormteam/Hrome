extends Area2D
## Шар, летящий по спирали к центру. При касании сектора ядра
## уничтожается (логику результата обрабатывает Core через area_entered).

var orb_color: String = "red"  # "red", "blue", "green", "black"
var speed: float = 150.0
var rotation_speed: float = 2.0
var radius: float = 600.0
var angle: float = 0.0

var is_morpher: bool = false
var has_morphed: bool = false
var has_collided: bool = false  # флаг: проверили столкновение с ядром (1 раз)

var trail_points: Array[Vector2] = []  # точки для хвоста

@onready var visual: Sprite2D = $Visual
@onready var trail: Line2D = $Trail

const MORPH_RADIUS: float = 150.0
const COLORS: Array[String] = ["red", "blue", "green"]


func _ready() -> void:
	trail.top_level = true
	# Ширина и кривая хвоста заданы в Orb.tscn (Width Curve + Gradient).
	add_to_group("orb")


func _process(delta: float) -> void:
	radius -= speed * delta
	angle += rotation_speed * delta

	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size / 2.0
	global_position = center + Vector2.from_angle(angle) * radius

	# Обновляем хвост
	trail_points.append(global_position)
	if trail_points.size() > 30:
		trail_points.pop_front()
	trail.points = trail_points
	trail.default_color = visual.modulate

	# Логика морфера
	if is_morpher and not has_morphed and radius <= MORPH_RADIUS:
		_morph_color()


func _morph_color() -> void:
	var available_colors: Array[String] = []
	for c: String in COLORS:
		if c != orb_color:
			available_colors.append(c)

	var new_color: String = available_colors[randi() % available_colors.size()]
	orb_color = new_color
	has_morphed = true

	match new_color:
		"red":
			visual.modulate = Color.RED
		"blue":
			visual.modulate = Color.BLUE
		"green":
			visual.modulate = Color.GREEN

	var original_color: Color = visual.modulate
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.05)
	tween.tween_property(visual, "modulate", original_color, 0.2)
