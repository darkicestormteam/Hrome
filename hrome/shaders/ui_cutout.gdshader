shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Если пиксель слишком тёмный — делаем прозрачным
	if (c.r < 0.1 && c.g < 0.1 && c.b < 0.1) {
		discard;
	}
	// Умножаем на COLOR (modulate), чтобы слоты красились в нужный цвет
	COLOR = c * COLOR;
}
