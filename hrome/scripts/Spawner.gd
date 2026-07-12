extends Node
## Спавнер шаров. Создаёт шары, бомбы и морферы по таймеру.
## Цвета шаров настраиваются в инспекторе (экспортированные поля ниже),
## чтобы вы могли визуально задать нужные цвета для каждого типа.

@onready var spawn_timer: Timer = $SpawnTimer

const ORB_SCENE: PackedScene = preload("res://scenes/Orb.tscn")
const COLORS: Array[String] = ["red", "blue", "green"]
const BOMB_CHANCE: float = 0.15  # 15% вероятность спавна бомбы
const MORPHER_CHANCE: float = 0.10  # 10% вероятность спавна морфера
const MIN_WAIT_TIME: float = 0.5  # минимальная задержка между спавнами

# Цвета шаров — настраивайте в инспекторе ноды Spawner.
@export var color_red: Color = Color("ff2018")
@export var color_blue: Color = Color("3ca7ff")
@export var color_green: Color = Color("00ff00")
@export var color_morpher: Color = Color.WHITE
@export var color_bomb: Color = Color.WHITE

var gm: Node


func _ready() -> void:
	gm = get_node("/root/GameManager")
	spawn_timer.timeout.connect(_on_spawn)
	gm.sector_changed.connect(_on_sector_changed)


func _on_spawn() -> void:
	## Создаёт новый шар, бомбу или морфера.
	var orb_instance = ORB_SCENE.instantiate()

	var current_sector: int = gm.current_sector

	# Если активен Монохром — все новые шары получают целевой цвет комбо
	var is_monochrome: bool = gm.buffs.monochrome_timer.time_left > 0.0

	# С 4-го сектора есть шанс спавна морфера
	if current_sector >= 4 and randf() < MORPHER_CHANCE:
		# Спавним морфера — передаём ему красивые цвета из инспектора
		var random_idx: int = randi() % COLORS.size()
		var random_color: String = COLORS[random_idx]
		orb_instance.orb_color = random_color
		orb_instance.is_morpher = true
		# Передаём морферу цвета для смены (без чёрного)
		var morph_names: Array[String] = ["red", "blue", "green"]
		var morph_colors_arr: Array[Color] = [color_red, color_blue, color_green]
		orb_instance.setup_morpher(morph_names, morph_colors_arr)
		var visual: Sprite2D = orb_instance.get_node("Visual")
		match random_color:
			"red":
				visual.modulate = color_red
			"blue":
				visual.modulate = color_blue
			"green":
				visual.modulate = color_green
	elif randf() < BOMB_CHANCE:
		# Спавним бомбу
		if is_monochrome:
			# При монохроме бомба становится цветом из последовательности
			var mono_color: String = gm.combo_sequence[0] if gm.combo_sequence.size() > 0 else "red"
			orb_instance.orb_color = mono_color
			var visual: Sprite2D = orb_instance.get_node("Visual")
			match mono_color:
				"red":
					visual.modulate = color_red
				"blue":
					visual.modulate = color_blue
				"green":
					visual.modulate = color_green
		else:
			orb_instance.orb_color = "black"
			var visual: Sprite2D = orb_instance.get_node("Visual")
			visual.modulate = color_bomb
	else:
		# Спавним обычный шар
		var random_color: String = COLORS[randi() % COLORS.size()]
		if is_monochrome:
			random_color = gm.combo_sequence[0] if gm.combo_sequence.size() > 0 else "red"
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
