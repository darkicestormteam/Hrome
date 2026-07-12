extends Sprite2D
## Световая волна — тонкая полоса с аддитивным блендингом,
## пролетающая через экран и подсвечивающая фон.

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0


func _ready() -> void:
	# Градиентная текстура: вертикальный градиент сверху вниз
	var tex := GradientTexture2D.new()
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	tex.gradient = Gradient.new()
	tex.gradient.add_point(0.0, Color(1, 1, 1, 0.0))
	tex.gradient.add_point(0.5, Color(1, 1, 1, 1.0))
	tex.gradient.add_point(1.0, Color(1, 1, 1, 0.0))
	self.texture = tex

	# Аддитивный блендинг для свечения
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	self.material = mat

	# Широкая тонкая полоса
	scale = Vector2(40.0, 1.0)

	add_to_group("light_wave")


func _process(delta: float) -> void:
	global_position += direction * speed * delta

	var viewport_size: Vector2 = get_viewport_rect().size
	# Удаляем, когда вышли за экран больше чем на 300 пикселей
	if global_position.x < -300.0 or global_position.x > viewport_size.x + 300.0 \
			or global_position.y < -300.0 or global_position.y > viewport_size.y + 300.0:
		queue_free()
