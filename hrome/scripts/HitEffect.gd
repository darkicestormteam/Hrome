extends Node2D
## Эффект взрыва частиц при столкновении шара с ядром.

@onready var particles: CPUParticles2D = $Particles

var _color: Color = Color.WHITE


func _ready() -> void:
	# ВАЖНЫЙ ПОРЯДОК: local_coords ДО emitting, иначе частицы вылетят в (0,0) экрана
	particles.one_shot = true
	particles.local_coords = true
	particles.color = _color
	particles.emitting = true
	# Автоудаление после завершения анимации частиц
	get_tree().create_timer(0.6).timeout.connect(func(): queue_free())


func set_color(color: Color) -> void:
	_color = color
	if is_node_ready():
		particles.color = color
