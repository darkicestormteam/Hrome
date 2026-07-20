extends Node
## Глобальный менеджер игры. Управляет счётом, HP, комбо, секторами, состоянием и системой Цветовых Комбо.

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

# Сигналы цветового комбо
signal combo_updated(sequence: Array[String], progress: int, tier: int)
signal combo_reward_triggered(reward_name: String)
signal combo_failed()
signal combo_timer_tick(time_left: float)

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

const SECTOR_DURATION: float = 45.0

var sector_timer: Timer
var combo_cooldown_timer: Timer

# --- Цветовое Комбо (Sequence) ---
var combo_active: bool = false
var combo_tier: int = 3
var combo_sequence: Array[String] = []
var combo_progress: int = 0
var combo_reward: String = ""

const COMBO_COLORS: Array[String] = ["red", "blue", "green"]
const COMBO_TIME_LIMIT: float = 15.0

var combo_timer: float = 0.0

# Неоновые цвета для UI — Spawner задаёт их через словарь
var combo_ui_colors: Dictionary = {}

# Награды для tier 3
const REWARDS_T3: Array[String] = ["shield", "shockwave", "slowmo", "score1000"]
# Награды для tier 4 (добавляются к T3)
const REWARDS_T4: Array[String] = ["hp", "monochrome", "score1500"]

var buffs: Node


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	sector_timer = Timer.new()
	sector_timer.name = "SectorTimer"
	sector_timer.wait_time = SECTOR_DURATION
	sector_timer.one_shot = false
	sector_timer.timeout.connect(_on_sector_timer_timeout)
	add_child(sector_timer)

	combo_cooldown_timer = Timer.new()
	combo_cooldown_timer.name = "ComboCooldownTimer"
	combo_cooldown_timer.wait_time = 30.0
	combo_cooldown_timer.one_shot = true
	combo_cooldown_timer.timeout.connect(_on_combo_cooldown_timeout)
	add_child(combo_cooldown_timer)

	buffs = Node.new()
	buffs.name = "ComboBuffs"
	buffs.set_script(preload("res://scripts/ComboBuffs.gd"))
	add_child(buffs)


func _process(delta: float) -> void:
	if combo_active and game_state == GameState.PLAYING:
		combo_timer -= delta
		combo_timer_tick.emit(combo_timer)
		if combo_timer <= 0.0:
			_fail_combo(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_execute_reward("shield")
			KEY_2:
				_execute_reward("shockwave")
			KEY_3:
				_execute_reward("slowmo")
			KEY_4:
				_execute_reward("score1000")
			KEY_5:
				_execute_reward("hp")
			KEY_6:
				_execute_reward("monochrome")


func _on_sector_timer_timeout() -> void:
	current_sector += 1

	# Обновляем tier для следующего комбо, но текущее не трогаем
	if current_sector == 1 and not combo_active and combo_cooldown_timer.time_left <= 0:
		combo_tier = 3
		combo_active = true
		_roll_new_combo()
	elif current_sector == 2:
		combo_tier = 4


func _start_combo_cooldown() -> void:
	combo_active = false
	combo_failed.emit()
	combo_cooldown_timer.start()


func _on_combo_cooldown_timeout() -> void:
	combo_active = true
	_roll_new_combo()
	# Принудительно показываем UI (на случай, если _roll_new_combo не сработал)
	combo_updated.emit(combo_sequence, combo_progress, combo_tier)


func _roll_new_combo() -> void:
	if not combo_active:
		return

	combo_sequence.clear()
	for i in range(combo_tier):
		combo_sequence.append(COMBO_COLORS[randi() % COMBO_COLORS.size()])
	combo_progress = 0
	combo_timer = COMBO_TIME_LIMIT

	var rewards_pool: Array[String] = REWARDS_T3.duplicate()
	if combo_tier >= 4:
		rewards_pool += REWARDS_T4
	combo_reward = rewards_pool[randi() % rewards_pool.size()]

	combo_updated.emit(combo_sequence, combo_progress, combo_tier)


func register_combo_hit(orb_color: String) -> void:
	if not combo_active:
		return
	if orb_color == "black":
		return

	if combo_progress < combo_sequence.size() and orb_color == combo_sequence[combo_progress]:
		combo_progress += 1
		combo_timer += 3.0  # прибавляем 3 секунды за правильное попадание
		if combo_progress >= combo_tier:
			_execute_reward(combo_reward)
			_start_combo_cooldown()
		else:
			combo_updated.emit(combo_sequence, combo_progress, combo_tier)
	else:
		_fail_combo()


func register_combo_gap_hit() -> void:
	pass


func _fail_combo(is_timeout: bool = false) -> void:
	if not combo_active:
		return

	if is_timeout:
		# Время вышло — комбо провалено окончательно, запускаем кулдаун
		combo_progress = 0
		_start_combo_cooldown()
	else:
		# Игрок промахнулся цветом — сбрасываем прогресс, но комбо и таймер остаются
		combo_progress = 0
		# Обновляем UI, но НЕ эмитим combo_failed, чтобы UI не скрылся
		combo_updated.emit(combo_sequence, combo_progress, combo_tier)


func _execute_reward(reward: String) -> void:
	combo_reward_triggered.emit(reward)
	match reward:
		"score1000":
			score += 1000
		"score1500":
			score += 1500
		"shield":
			buffs.activate_shield(get_node("/root/GameManager/../Main/Core"))
		"slowmo":
			buffs.activate_slowmo()
		"shockwave":
			var pts: int = buffs.activate_shockwave()
			score += pts
		"hp":
			hp = min(hp + 1, 5)
		"monochrome":
			buffs.activate_monochrome(combo_sequence[0] if combo_sequence.size() > 0 else "red")


func add_score(val: int) -> void:
	var final_score: int = int(val * combo_multiplier)
	score += final_score
	combo_multiplier = minf(combo_multiplier + 0.1, 5.0)


func take_damage() -> void:
	if buffs and buffs.has_method("is_shield_active") and buffs.is_shield_active():
		buffs._on_shield_end()
		return
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

	# Сбрасываем кулдаун, если он был активен
	if combo_cooldown_timer.time_left > 0:
		combo_cooldown_timer.stop()

	combo_active = true
	combo_tier = 3
	combo_progress = 0
	combo_sequence.clear()
	combo_reward = ""
	combo_timer = COMBO_TIME_LIMIT
	_roll_new_combo()
