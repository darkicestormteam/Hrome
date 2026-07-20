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
@onready var spawner = $Spawner

# Главное меню
@onready var main_menu_screen: Control = $UI/MainMenuScreen
@onready var play_button: Button = $UI/MainMenuScreen/VBoxContainer/PlayButton
@onready var menu_settings_button: Button = $UI/MainMenuScreen/VBoxContainer/SettingsButton

var gm: Node

# UI для цветового комбо
@onready var combo_ui: Control = $UI/ComboUI
@onready var slots_container: HBoxContainer = $UI/ComboUI/SlotsContainer
@onready var reward_label: Label = $UI/ComboUI/RewardLabel
@onready var combo_timer_bar: ProgressBar = $UI/ComboUI/ComboTimerBar

# Каждый элемент: {"orb": TextureRect, "plate": ColorRect, "holder": Control}
# Слоты комбо из сцены
@onready var slot_holders: Array[Control] = [
	$UI/ComboUI/SlotsContainer/SlotHolder1,
	$UI/ComboUI/SlotsContainer/SlotHolder2,
	$UI/ComboUI/SlotsContainer/SlotHolder3,
	$UI/ComboUI/SlotsContainer/SlotHolder4
]

# Цвета таймера — редактируются в инспекторе
@export var timer_color_green: Color = Color(0.13, 0.80, 0.20, 1.0)  # зелёный (полный таймер)
@export var timer_color_red: Color = Color(1.0, 0.20, 0.20, 1.0)    # красный (конец)

var combo_slots: Array = []


func _collect_combo_slots() -> void:
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for i in range(4):
		var holder: Control = slot_holders[i]
		var plate: Panel = holder.get_node("Backplate" + str(i + 1))
		var orb: TextureRect = holder.get_node("OrbVisual" + str(i + 1))

		# StyleBoxFlat со скруглением
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		plate.add_theme_stylebox_override("panel", style)

		# Настройка текстуры и материала для основного шара
		var orb_tex = preload("res://assets/orb2.png")
		if orb_tex == null:
			orb_tex = preload("res://assets/orb.png")
		orb.texture = orb_tex
		orb.material = add_mat

		# Настройка Glow (нода уже есть в сцене)
		var glow: TextureRect = holder.get_node("GlowVisual" + str(i + 1))
		glow.texture = orb_tex
		glow.custom_minimum_size = orb.custom_minimum_size
		glow.expand_mode = orb.expand_mode
		glow.stretch_mode = orb.stretch_mode
		glow.modulate = Color(1, 1, 1, 0.0)  # невидим по умолчанию
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = glow_mat

		# Случайная фаза для свечения — чтобы не мигали синхронно
		var glow_phase: float = randf_range(0.0, PI * 2.0)
		holder.visible = false
		combo_slots.append({"orb": orb, "plate": plate, "holder": holder, "glow": glow, "glow_phase": glow_phase})


func _ready() -> void:
	gm = get_node("/root/GameManager")

	_collect_combo_slots()

	combo_timer_bar.min_value = 0.0
	combo_timer_bar.max_value = 15.0
	combo_timer_bar.value = 15.0
	combo_timer_bar.show_percentage = false
	combo_timer_bar.custom_minimum_size = Vector2(120, 8)

	gm.combo_ui_colors = {
		"red": Color("ff2018"),
		"blue": Color("3ca7ff"),
		"green": Color("00ff00")
	}

	gm.combo_updated.connect(_on_combo_updated)
	gm.combo_failed.connect(_on_combo_failed)
	gm.combo_timer_tick.connect(_on_combo_timer_tick)

	combo_ui.visible = false

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

	game_over_screen.visible = false
	settings_screen.visible = false
	gm.game_state = GameManager.GameState.MENU
	main_menu_screen.visible = true
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


func _on_combo_updated(sequence: Array[String], progress: int, tier: int) -> void:
	if sequence.size() == 0:
		combo_ui.visible = false
		return
	combo_ui.visible = true

	for i in range(4):
		var slot_data: Dictionary = combo_slots[i]
		var holder: Control = slot_data.holder

		if i < tier:
			holder.visible = true
			var target_color: Color = gm.combo_ui_colors.get(sequence[i], Color.WHITE)
			# Шар всегда яркий
			slot_data.orb.modulate = target_color
			# Подложка: зелёная если собрано, тёмная если нет
			var bg: Color = Color(0.2, 0.9, 0.3, 1.0) if i < progress else Color(0, 0, 0, 0)
			var sty := StyleBoxFlat.new()
			sty.bg_color = bg
			sty.corner_radius_top_left = 10
			sty.corner_radius_top_right = 10
			sty.corner_radius_bottom_left = 10
			sty.corner_radius_bottom_right = 10
			slot_data.plate.add_theme_stylebox_override("panel", sty)
		else:
			holder.visible = false

	reward_label.text = "REWARD: " + combo_name_to_text()

	combo_timer_bar.value = 15.0
	combo_timer_bar.modulate = Color.WHITE


func _on_combo_timer_tick(time_left: float) -> void:
	combo_timer_bar.value = maxf(time_left, 0.0)
	# Плавный переход от зелёного к красному
	var t: float = 1.0 - (time_left / 15.0)  # 0 = полный таймер, 1 = пустой
	combo_timer_bar.modulate = timer_color_green.lerp(timer_color_red, t)


func _on_combo_failed() -> void:
	combo_ui.visible = false
	for slot_data in combo_slots:
		if slot_data.holder.visible:
			var sty_red := StyleBoxFlat.new()
			sty_red.bg_color = Color(1, 0, 0, 0.5)
			sty_red.corner_radius_top_left = 10
			sty_red.corner_radius_top_right = 10
			sty_red.corner_radius_bottom_left = 10
			sty_red.corner_radius_bottom_right = 10
			slot_data.plate.add_theme_stylebox_override("panel", sty_red)
			var sty_clear := StyleBoxFlat.new()
			sty_clear.bg_color = Color(0, 0, 0, 0)
			sty_clear.corner_radius_top_left = 10
			sty_clear.corner_radius_top_right = 10
			sty_clear.corner_radius_bottom_left = 10
			sty_clear.corner_radius_bottom_right = 10
			# Возвращаем через таймер
			var tween: Tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_callback(func():
				slot_data.plate.add_theme_stylebox_override("panel", sty_clear)
			).set_delay(0.2)


func combo_name_to_text() -> String:
	match gm.combo_reward:
		"shield":
			return "SHIELD"
		"shockwave":
			return "SHOCKWAVE"
		"slowmo":
			return "SLOW MO"
		"score1000":
			return "+1000 SCORE"
		"score1500":
			return "+1500 SCORE"
		"hp":
			return "+1 HP"
		"monochrome":
			return "MONOCHROME"
		_:
			return ""


func _process(delta: float) -> void:
	if has_node("Background"):
		var breath: float = 0.8 + sin(Time.get_ticks_msec() * 0.001) * 0.2
		$Background.modulate.a = breath

	# Пульсация свечения орбов (каждый со своей случайной фазой)
	var gt: float = Time.get_ticks_msec() * 0.002
	for sd in combo_slots:
		if sd.holder.visible:
			var glow_alpha: float = 0.15 + sin(gt + sd.glow_phase) * 0.15
			sd.glow.modulate.a = glow_alpha
