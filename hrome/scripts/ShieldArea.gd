extends Area2D
## Область щита вокруг ядра. Когда активен — уничтожает входящие шары.
## Включается/выключается через `set_active(true/false)`.

@onready var shield_visual: Sprite2D = $ShieldVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var shield_active: bool = false


func _ready() -> void:
	monitoring = false
	shield_visual.visible = false
	collision_shape.disabled = true
	area_entered.connect(_on_area_entered)


func set_active(active: bool) -> void:
	shield_active = active
	monitoring = active
	shield_visual.visible = active
	collision_shape.disabled = not active


func _on_area_entered(area: Area2D) -> void:
	if not shield_active:
		return
	if area.is_in_group("orb") and not area.has_collided:
		area.has_collided = true  # чтобы Core не обработал повторно
		area.queue_free()
		set_active(false)
