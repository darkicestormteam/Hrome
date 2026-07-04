extends Node
## Спавнер шаров. Создаёт шары и бомбы по таймеру.

@onready var spawn_timer: Timer = $SpawnTimer

const ORB_SCENE: PackedScene = preload("res://scenes/Orb.tscn")
const COLORS: Array[String] = ["red", "blue", "green"]
const BOMB_CHANCE: float = 0.15  # 15% вероятность спавна бомбы


func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn)


func _on_spawn() -> void:
	## Создаёт новый шар или бомбу со случайными параметрами.
	var orb_instance: Area2D = ORB_SCENE.instantiate()
	
	# Определяем, будет ли бомба (15%) или обычный шар (85%)
	if randf() < BOMB_CHANCE:
		# Спавним бомбу
		orb_instance.orb_color = "black"
		var visual: Sprite2D = orb_instance.get_node("Visual")
		visual.modulate = Color.BLACK
		visual.scale = Vector2(0.3, 0.3)  # стандартный размер, как у обычных шаров
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
	
	# Случайный стартовый угол
	orb_instance.angle = randf_range(0.0, TAU)
	
	# Добавляем в корень сцены
	get_tree().root.add_child(orb_instance)
