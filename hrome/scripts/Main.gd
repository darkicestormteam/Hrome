extends Node2D
## Главная сцена. Управляет UI, экраном Game Over, настройками и рестартом.

@onready var score_label: Label = $UI/ScoreLabel
@onready var hp_label: Label = $UI/HPLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var sector_label: Label = $UI/SectorLabel
@onready var game_over_screen: Control = $UI/GameOverScreen
@onready var final_score_label: Label = $UI/GameOverScreen/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $UI/GameOverScreen/VBoxContainer/RestartButton
@onready var settings_button: Button = $UI/GameOverScreen/VBoxContainer/SettingsButton
@onready var settings_screen: Control = $UI/SettingsScreen
@onready var music_slider: HSlider = $UI/SettingsScreen/VBoxContainer/HBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $UI/SettingsScreen/VBoxContainer/HBoxContainer2/SfxSlider
@onready var music_mute_button: Button = $UI/MusicMuteButton
@onready var sfx_mute_button: Button = $UI/SfxMuteButton
@onready var close_settings_button: Button = $UI/SettingsScreen/VBoxContainer/CloseSettingsButton
@onready var core: Node2D = $Core
@onready var spawner: Node = $Spawner

var gm: Node


func _ready() -> void:
	gm = get_node("/root/GameManager")
	
	var viewport_size: Vector2 = get_viewport_rect().size
	core.global_position = viewport_size / 2.0
	
	gm.score_changed.connect(_on_score_changed)
	gm.hp_changed.connect(_on_hp_changed)
	gm.combo_changed.connect(_on_combo_changed)
	gm.sector_changed.connect(_on_sector_changed)
	gm.game_over.connect(_on_game_over)
	
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_open_settings)
	close_settings_button.pressed.connect(_on_close_settings)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_mute_button.pressed.connect(_on_music_mute_pressed)
	sfx_mute_button.pressed.connect(_on_sfx_mute_pressed)
	
	_on_score_changed(gm.score)
	_on_hp_changed(gm.hp)
	_on_combo_changed(gm.combo_multiplier)
	_on_sector_changed(gm.current_sector)
	
	gm.reset_game()


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
