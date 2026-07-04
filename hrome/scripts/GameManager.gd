extends Node
## Глобальный менеджер игры. Управляет счётом, HP, комбо и состоянием.
## Зарегистрирован как Autoload (Singleton).

enum GameState {
	MENU,
	PLAYING,
	GAME_OVER
}

signal score_changed(new_score: int)
signal hp_changed(new_hp: int)
signal combo_changed(new_combo: float)
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
			game_over.emit()

var combo_multiplier: float = 1.0:
	set(value):
		combo_multiplier = value
		combo_changed.emit(combo_multiplier)

var game_state: GameState = GameState.MENU


func add_score(val: int) -> void:
	## Добавляет очки с учётом множителя комбо.
	var final_score: int = int(val * combo_multiplier)
	score += final_score
	# Увеличиваем множитель, но не выше x5.0
	combo_multiplier = minf(combo_multiplier + 0.1, 5.0)


func take_damage() -> void:
	## Наносит урон игроку и сбрасывает комбо.
	hp -= 1
	combo_multiplier = 1.0


func reset_game() -> void:
	## Сбрасывает игру в начальное состояние.
	score = 0
	hp = 3
	combo_multiplier = 1.0
	game_state = GameState.PLAYING
