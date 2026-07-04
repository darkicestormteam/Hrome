extends Area2D
## Шар, летящий по спирали к центру.

var orb_color: String = "red"  # "red", "blue", "green", "black"
var speed: float = 150.0
var rotation_speed: float = 2.0
var radius: float = 600.0
var angle: float = 0.0


func _process(delta: float) -> void:
	radius -= speed * delta
	angle += rotation_speed * delta
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size / 2.0
	global_position = center + Vector2.from_angle(angle) * radius
	
	# Если шар достиг ядра
	if radius <= 80.0:
		var core: Node = get_tree().get_first_node_in_group("core")
		if core != null and core.has_method("check_hit"):
			core.check_hit(orb_color, angle)
		queue_free()
