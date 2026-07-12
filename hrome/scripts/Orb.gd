extends Area2D
## Шар, летящий по спирали к центру. При касании сектора ядра
## уничтожается (логику результата обрабатывает Core через area_entered).

var orb_color: String = "red"  # "red", "blue", "green", "black"
var speed: float = 150.0
var speed_mult: float = 1.0  # для баффа slowmo
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
const MORPH_STOP_DISTANCE: float = 200.0  # на этом расстоянии морфер перестаёт менять цвет
const MORPH_INTERVAL: float = 1.0  # каждую секунду новый цвет

# Массивы для морфера — Spawner задаёт их через setup_morpher()
var morph_color_names: Array[String] = ["red", "blue", "green"]
var morph_colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN]

var morph_timer: float = 0.0  # таймер для смены цвета морфера


## Устанавливает множитель скорости (для баффа slowmo).
func set_speed_mult(mult: float) -> void:
	speed_mult = mult


func _ready() -> void:
	trail.top_level = true
	visual.z_index = 1

	# Программная настройка Line2D, чтобы толщина и прозрачность работали
	# независимо от ресурсов в .tscn
	trail.width = 16.0
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND

	# Кривая толщины: 0.0 = конец хвоста (тонкий), 1.0 = у шара (толстый)
	var w_curve := Curve.new()
	w_curve.add_point(Vector2(0.0, 0.0))
	w_curve.add_point(Vector2(1.0, 1.0))
	trail.width_curve = w_curve

	# Хвост просто копирует цвет шара (без градиента)
	trail.gradient = null

	add_to_group("orb")

	# Синхронизируем цвет хвоста с цветом спрайта (который задал Spawner)
	_apply_color_to_trail(visual.modulate)


func _process(delta: float) -> void:
	radius -= speed * speed_mult * delta
	angle += rotation_speed * delta

	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size / 2.0
	global_position = center + Vector2.from_angle(angle) * radius

	# Обновляем хвост
	trail_points.append(global_position)
	if trail_points.size() > 30:
		trail_points.pop_front()
	trail.points = trail_points
	_apply_color_to_trail(visual.modulate)

	# Логика морфера — плавная смена цвета раз в секунду до достижения MORPH_STOP_DISTANCE
	if is_morpher and radius > MORPH_STOP_DISTANCE:
		morph_timer += delta
		if morph_timer >= MORPH_INTERVAL:
			morph_timer = 0.0
			_do_morph()


## Плавно меняет цвет морфера на случайный другой цвет.
func _do_morph() -> void:
	# Выбираем случайный индекс, не совпадающий с текущим цветом спрайта
	var idx: int = randi() % morph_colors.size()
	if morph_colors[idx] == visual.modulate and morph_colors.size() > 1:
		idx = (idx + 1) % morph_colors.size()

	var new_color: Color = morph_colors[idx]
	orb_color = morph_color_names[idx]

	# Плавный переход к новому цвету
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "modulate", new_color, 0.4)

	# Хвост синхронизируем сразу после завершения перехода
	tween.finished.connect(func():
		_apply_color_to_trail(visual.modulate)
	)


## Устанавливает цвета для смены морфера (вызывается из Spawner перед _ready).
func setup_morpher(names: Array[String], colors: Array[Color]) -> void:
	morph_color_names = names
	morph_colors = colors


## Преобразует строковое имя цвета в Color.
## "black" отображается как тёмно-красный, чтобы шар и хвост были видны на тёмном фоне.
func _orb_color_to_color(color_name: String) -> Color:
	match color_name:
		"red":
			return Color.RED
		"blue":
			return Color.BLUE
		"green":
			return Color.GREEN
		"black":
			return Color(0.4, 0.0, 0.0, 1.0)  # тёмно-красный
		_:
			return Color.WHITE


## Применяет цвет к узлу хвоста (Line2D).
## Просто копирует цвет спрайта.
func _apply_color_to_trail(color: Color) -> void:
	trail.default_color = color
