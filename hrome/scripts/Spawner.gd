extends Node
## Спавнер шаров. Создаёт шары, бомбы и морферы по таймеру.

@onready var spawn_timer: Timer = $SpawnTimer

const ORB_SCENE: PackedScene = preload("res://scenes/Orb.tscn")
const COLORS: Array[String] = ["red", "blue", "green"]
const BOMB_CHANCE: float = 0.15  # 15% вероятность спавна бомбы
const MORPHER_CHANCE: float = 0.10  # 10% вероятность спавна морфера (с 4-го сектора)
const MIN_WAIT_TIME: float = 0.5  # минимальная задержка между спавнами

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
		match random_color:
			"red":
				visual.modulate = Color.RED
			"blue":
				visual.modulate = Color.BLUE
			"green":
				visual.modulate = Color.GREEN
		# Визуальный маркер морфера — белая окантовка через scale
		visual.scale = Vector2(0.4, 0.4)  # чуть крупнее для заметности
	elif randf() < BOMB_CHANCE:
		# Спавним бомбу
		orb_instance.orb_color = "black"
		var visual: Sprite2D = orb_instance.get_node("Visual")
		visual.modulate = Color.BLACK
		visual.scale = Vector2(0.3, 0.3)
	else:
		# Спавним обычный шар
		var random_color: String = COLORS[randi() % COLORS.size()]
		orb_instance.orb_color = random_color
		var visual: Sprite2D = orb_instance.get_node("Visual")
		match random_color:
			"red":
				visual.modulate = Color.RED
			"blue":
				visual.modulate = Color.BLUE
			"green":
				visual.modulate = Color.GREEN
		visual.scale = Vector2(0.3, 0.3)
	
	# Случайный стартовый угол
	orb_instance.angle = randf_range(0.0, TAU)
	
	# Добавляем в корень сцены
	get_tree().root.add_child(orb_instance)


func _on_sector_changed(new_sector: int) -> void:
	## Увеличивает скорость спавна при повышении сектора.
	var new_wait_time: float = maxf(1.4 - (new_sector - 1) * 0.2, MIN_WAIT_TIME)
	spawn_timer.wait_time = new_wait_time
	spawn_timer.start()
