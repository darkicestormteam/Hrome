extends Node
## Глобальный менеджер звука. Управляет музыкой и звуковыми эффектами.

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

# Индивидуальная громкость для каждого звука (в децибелах)
const SFX_VOLUMES: Dictionary = {
	"absorb": -8.0,
	"gap": -4.0,
	"damage": -6.0,
	"gameover": -3.0
}

var music_volume_db: float = 0.0
var sfx_volume_db: float = 0.0
var music_muted: bool = false
var sfx_muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	sfx_player = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	add_child(music_player)
	
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	
	var music: AudioStream = load("res://audio/music.mp3")
	if music:
		music_player.stream = music


func play_sfx(file_name: String) -> void:
	var sfx: AudioStream = load("res://audio/" + file_name + ".wav")
	if sfx == null:
		sfx = load("res://audio/" + file_name + ".mp3")
	if sfx:
		sfx_player.stream = sfx
		sfx_player.play()
	else:
		printerr("АУДИО ФАЙЛ НЕ НАЙДЕН: res://audio/" + file_name + ".wav или .mp3")


func play_music() -> void:
	if not music_player.playing:
		music_player.play()


func stop_music() -> void:
	music_player.stop()


func set_music_volume(value_db: float) -> void:
	music_volume_db = value_db
	if not music_muted:
		var idx: int = AudioServer.get_bus_index("Music")
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, value_db)


func set_sfx_volume(value_db: float) -> void:
	sfx_volume_db = value_db
	if not sfx_muted:
		var idx: int = AudioServer.get_bus_index("SFX")
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, value_db)


func toggle_music_mute() -> void:
	music_muted = not music_muted
	var idx: int = AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, -80.0 if music_muted else music_volume_db)


func toggle_sfx_mute() -> void:
	sfx_muted = not sfx_muted
	var idx: int = AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, -80.0 if sfx_muted else sfx_volume_db)
