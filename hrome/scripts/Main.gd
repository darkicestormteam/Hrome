extends Node2D
## Главная сцена. Управляет UI и подключением к GameManager.

@onready var score_label: Label = $UI/ScoreLabel
@onready var hp_label: Label = $UI/HPLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var core: Node2D = $Core

var gm: Node


func _ready() -> void:
	gm = get_node("/root/GameManager")
	
	# Позиционируем ядро по центру экрана
	var viewport_size: Vector2 = get_viewport_rect().size
	core.global_position = viewport_size / 2.0
	
	# Подключаемся к сигналам GameManager
	gm.score_changed.connect(_on_score_changed)
	gm.hp_changed.connect(_on_hp_changed)
	gm.combo_changed.connect(_on_combo_changed)
	gm.game_over.connect(_on_game_over)
	
	# Начинаем игру
	gm.reset_game()


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)


func _on_hp_changed(new_hp: int) -> void:
	hp_label.text = "HP: " + str(new_hp)


func _on_combo_changed(new_combo: float) -> void:
	## Обновляет отображение множителя комбо.
	var text: String = "x" + "%.1f" % new_combo
	combo_label.text = text
	
	# Меняем цвет в зависимости от значения множителя
	if new_combo >= 3.0:
		combo_label.modulate = Color.RED
	elif new_combo >= 2.0:
		combo_label.modulate = Color.YELLOW
	else:
		combo_label.modulate = Color.WHITE


func _on_game_over() -> void:
	score_label.text = "GAME OVER! Score: " + str(gm.score)
