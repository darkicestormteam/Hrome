extends Node
## Спавнер шаров. Создаёт шары, бомбы и морферы по таймеру.
## Цвета шаров настраиваются в инспекторе (экспортированные поля ниже),
## чтобы вы могли визуально задать нужные цвета для каждого типа.

@onready var spawn_timer: Timer = $SpawnTimer

const ORB_SCENE: PackedScene = preload("res://scenes/Orb.tscn")
const COLORS: Array[String] = ["red", "blue", "green"]
const BOMB_CHANCE: float = 0.15  # 15% вероятность спавна бомбы
const MORPHER_CHANCE: float = 0.10  # 10% вероятность спавна морфера (с 4-го сектора)
const MIN_WAIT_TIME: float = 0.5  # минимальная задержка между спавнами

# Цвета шаров — настраивайте в инспекторе ноды Spawner.
@export var color_red: Color = Color.RED
@export var color_blue: Color = Color.BLUE
@export var color_green: Color = Color.GREEN
@export var color_morpher: Color = Color.WHITE
@export var color_bomb: Color = Color.WHITE

var gm: Node


func _ready() -> void:
	gm = get_node("/root/GameManager")
	spawn_timer.timeout.connect(_on_spawn)
	gm.sector_changed.connect(_on_sector_changed)


func _on_spawn() -> void:
	## Создаёт новый шар, бомбу или морфера.
	var orb_instance: Area2D = ORB_SCENE.instantiate()

	var current_sector: int = gm.current_sector

	# С 4-го сектора есть шанс спавна морфера
	if current_sector >= 4 and randf() < MORPHER_CHANCE:
		# Спавним морфера
		var random_color: String = COLORS[randi() % COLORS.size()]
		orb_instance.orb_color = random_color
		orb_instance.is_morpher = true
		var visual: Sprite2D = orb_instance.get_node("Visual")
		visual.modulate = color_morpher
	elif randf() < BOMB_CHANCE:
		# Спавним бомбу (использует ту же текстуру orb.png, что и обычные шары)
		orb_instance.orb_color = "black"
		var visual: Sprite2D = orb_instance.get_node("Visual")
		visual.modulate = color_bomb
	else:
		# Спавним обычный шар
		var random_color: String = COLORS[randi() % COLORS.size()]
		orb_instance.orb_color = random_color
		var visual: Sprite2D = orb_instance.get_node("Visual")
		match random_color:
			"red":
				visual.modulate = color_red
			"blue":
				visual.modulate = color_blue
			"green":
				visual.modulate = color_green

	# Случайный стартовый угол
	orb_instance.angle = randf_range(0.0, TAU)

	# Добавляем в корень сцены
	get_tree().root.add_child(orb_instance)


func _on_sector_changed(new_sector: int) -> void:
	## Увеличивает скорость спавна при повышении сектора.
	var new_wait_time: float = maxf(1.4 - (new_sector - 1) * 0.2, MIN_WAIT_TIME)
	spawn_timer.wait_time = new_wait_time
	spawn_timer.start()
