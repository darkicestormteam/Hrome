extends Node2D
## Главная сцена. Управляет UI, главным меню, экраном Game Over, настройками и рестартом.

@onready var score_label: Label = $UI/ScoreLabel
@onready var hp_label: Label = $UI/HPLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var sector_label: Label = $UI/SectorLabel
@onready var game_over_screen: Control = $UI/GameOverScreen
@onready var final_score_label: Label = $UI/GameOverScreen/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $UI/GameOverScreen/VBoxContainer/RestartButton
@onready var game_over_settings_button: Button = $UI/GameOverScreen/VBoxContainer/SettingsButton
@onready var settings_screen: Control = $UI/SettingsScreen
@onready var music_slider: HSlider = $UI/SettingsScreen/VBoxContainer/HBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $UI/SettingsScreen/VBoxContainer/HBoxContainer2/SfxSlider
@onready var music_mute_button: Button = $UI/MusicMuteButton
@onready var sfx_mute_button: Button = $UI/SfxMuteButton
@onready var close_settings_button: Button = $UI/SettingsScreen/VBoxContainer/CloseSettingsButton
@onready var core: Node2D = $Core
@onready var spawner: Node = $Spawner

# Главное меню
@onready var main_menu_screen: Control = $UI/MainMenuScreen
@onready var play_button: Button = $UI/MainMenuScreen/VBoxContainer/PlayButton
@onready var menu_settings_button: Button = $UI/MainMenuScreen/VBoxContainer/SettingsButton

var gm: Node


func _ready() -> void:
	gm = get_node("/root/GameManager")
	# Всегда реагируем на ввод, даже когда дерево на паузе (экран Game Over).
	process_mode = Node.PROCESS_MODE_ALWAYS

	var viewport_size: Vector2 = get_viewport_rect().size
	core.global_position = viewport_size / 2.0

	gm.score_changed.connect(_on_score_changed)
	gm.hp_changed.connect(_on_hp_changed)
	gm.combo_changed.connect(_on_combo_changed)
	gm.sector_changed.connect(_on_sector_changed)
	gm.game_over.connect(_on_game_over)

	restart_button.pressed.connect(_on_restart_pressed)
	game_over_settings_button.pressed.connect(_on_open_settings)
	close_settings_button.pressed.connect(_on_close_settings)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_mute_button.pressed.connect(_on_music_mute_pressed)
	sfx_mute_button.pressed.connect(_on_sfx_mute_pressed)

	play_button.pressed.connect(_on_play_button_pressed)
	menu_settings_button.pressed.connect(_on_menu_settings_pressed)
	play_button.mouse_entered.connect(_on_button_hover.bind(play_button))
	play_button.mouse_exited.connect(_on_button_unhover.bind(play_button))
	menu_settings_button.mouse_entered.connect(_on_button_hover.bind(menu_settings_button))
	menu_settings_button.mouse_exited.connect(_on_button_unhover.bind(menu_settings_button))

	_on_score_changed(gm.score)
	_on_hp_changed(gm.hp)
	_on_combo_changed(gm.combo_multiplier)
	_on_sector_changed(gm.current_sector)

	# Стартуем в главном меню: прячем игровые экраны, замораживаем игру.
	game_over_screen.visible = false
	settings_screen.visible = false
	gm.game_state = GameManager.GameState.MENU
	main_menu_screen.visible = true
	# Замораживаем игровые узлы (а не всё дерево), чтобы tween меню работал.
	core.process_mode = Node.PROCESS_MODE_DISABLED
	spawner.process_mode = Node.PROCESS_MODE_DISABLED
	_animate_menu_in()


func _animate_menu_in() -> void:
	main_menu_screen.modulate = Color(1, 1, 1, 0)
	main_menu_screen.scale = Vector2(0.9, 0.9)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(main_menu_screen, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(main_menu_screen, "scale", Vector2(1.0, 1.0), 0.3)


func _on_button_hover(button: Button) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.12)


func _on_button_unhover(button: Button) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.12)


func _on_play_button_pressed() -> void:
	main_menu_screen.visible = false
	core.process_mode = Node.PROCESS_MODE_INHERIT
	spawner.process_mode = Node.PROCESS_MODE_INHERIT
	gm.reset_game()
	if spawner.has_node("SpawnTimer"):
		spawner.spawn_timer.start()


func _on_menu_settings_pressed() -> void:
	main_menu_screen.visible = false
	settings_screen.visible = true


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)


func _on_hp_changed(new_hp: int) -> void:
	hp_label.text = "HP: " + str(new_hp)


func _on_combo_changed(new_combo: float) -> void:
	var text: String = "x" + "%.1f" % new_combo
	combo_label.text = text
	if new_combo >= 3.0:
		combo_label.modulate = Color.RED
	elif new_combo >= 2.0:
		combo_label.modulate = Color.YELLOW
	else:
		combo_label.modulate = Color.WHITE


func _on_sector_changed(new_sector: int) -> void:
	sector_label.text = "Sector: " + str(new_sector)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sector_label, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(sector_label, "scale", Vector2(1.0, 1.0), 0.3)


func _on_game_over() -> void:
	final_score_label.text = "Score: " + str(gm.score)
	game_over_screen.visible = true
	if spawner.has_node("SpawnTimer"):
		spawner.spawn_timer.stop()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	game_over_screen.visible = false
	for orb: Node in get_tree().get_nodes_in_group("orb"):
		orb.queue_free()
	gm.reset_game()
	if spawner.has_node("SpawnTimer"):
		spawner.spawn_timer.start()


func _on_open_settings() -> void:
	var audio: Node = get_node("/root/AudioManager")
	music_slider.value = audio.music_volume_db
	sfx_slider.value = audio.sfx_volume_db
	music_mute_button.text = "UNMUTE" if audio.music_muted else "MUTE"
	sfx_mute_button.text = "UNMUTE" if audio.sfx_muted else "MUTE"
	settings_screen.visible = true
	game_over_screen.visible = false


func _on_close_settings() -> void:
	settings_screen.visible = false
	if gm.game_state == GameManager.GameState.MENU:
		main_menu_screen.visible = true
	else:
		game_over_screen.visible = true


func _on_music_slider_changed(value: float) -> void:
	get_node("/root/AudioManager").set_music_volume(value)


func _on_sfx_slider_changed(value: float) -> void:
	get_node("/root/AudioManager").set_sfx_volume(value)


func _on_music_mute_pressed() -> void:
	var audio: Node = get_node("/root/AudioManager")
	audio.toggle_music_mute()
	music_mute_button.text = "UNMUTE" if audio.music_muted else "MUTE"


func _on_sfx_mute_pressed() -> void:
	var audio: Node = get_node("/root/AudioManager")
	audio.toggle_sfx_mute()
	sfx_mute_button.text = "UNMUTE" if audio.sfx_muted else "MUTE"
