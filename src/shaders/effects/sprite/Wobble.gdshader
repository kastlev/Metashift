shader_type canvas_item;

/**
 * Intensidad de la deformación.
 * Valores altos generan un movimiento más exagerado.
 */
uniform float wobble_strength : hint_range(0.0, 3.0) = 0.8;

/**
 * Velocidad de la animación.
 */
uniform float wobble_speed : hint_range(0.0, 10.0) = 2.0;

void vertex() {
	VERTEX.x += sin(TIME * wobble_speed + VERTEX.y * 0.3) * wobble_strength;
	VERTEX.y += cos(TIME * wobble_speed * 0.7 + VERTEX.x * 0.3) * wobble_strength * 0.5;
}

void fragment() {
	vec4 sprite = texture(TEXTURE, UV);

	// Compatibilidad con flashes y modulación externa
	if (COLOR.r > 1.0 || COLOR.g != COLOR.b) {
		sprite.rgb = COLOR.rgb * sprite.a;
	}

	COLOR = sprite;
}