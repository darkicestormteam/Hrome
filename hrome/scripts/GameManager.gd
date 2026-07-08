extends Node
## Глобальный менеджер игры. Управляет счётом, HP, комбо, секторами и состоянием.

enum GameState {
	MENU,
	PLAYING,
	GAME_OVER
}

signal score_changed(new_score: int)
signal hp_changed(new_hp: int)
signal combo_changed(new_combo: float)
signal sector_changed(new_sector: int)
signal game_over

var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

var hp: int = 3:
	set(value):
		hp = value
		hp_changed.emit(hp)
		if hp <= 0:
			game_state = GameState.GAME_OVER
			var audio: Node = get_node("/root/AudioManager")
			audio.stop_music()
			audio.play_sfx("gameover")
			game_over.emit()
			call_deferred("_pause_game")


func _pause_game() -> void:
	get_tree().paused = true

var combo_multiplier: float = 1.0:
	set(value):
		combo_multiplier = value
		combo_changed.emit(combo_multiplier)

var current_sector: int = 1:
	set(value):
		current_sector = value
		sector_changed.emit(current_sector)

var game_state: GameState = GameState.MENU

const SECTOR_DURATION: float = 45.0  # каждые 45 секунд новый сектор

var sector_timer: Timer  # создаётся в _ready()


func _ready() -> void:
	# Чтобы можно было снять паузу из рестарта
	process_mode = PROCESS_MODE_ALWAYS
	
	sector_timer = Timer.new()
	sector_timer.name = "SectorTimer"
	sector_timer.wait_time = SECTOR_DURATION
	sector_timer.one_shot = false
	sector_timer.timeout.connect(_on_sector_timer_timeout)
	add_child(sector_timer)


func _on_sector_timer_timeout() -> void:
	current_sector += 1


func add_score(val: int) -> void:
	var final_score: int = int(val * combo_multiplier)
	score += final_score
	combo_multiplier = minf(combo_multiplier + 0.1, 5.0)


func take_damage() -> void:
	hp -= 1
	combo_multiplier = 1.0


func reset_game() -> void:
	score = 0
	hp = 3
	combo_multiplier = 1.0
	current_sector = 1
	game_state = GameState.PLAYING
	sector_timer.start()
	var audio: Node = get_node("/root/AudioManager")
	audio.play_music()
