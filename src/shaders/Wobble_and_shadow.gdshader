shader_type canvas_item;

// Shadow
uniform vec2 shadow_offset = vec2(0.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

// Wobble
uniform float wobble_strength : hint_range(0.0, 3.0) = 0.8;
uniform float wobble_speed : hint_range(0.0, 10.0) = 2.0;

void vertex() {
	VERTEX.x += sin(TIME * wobble_speed + VERTEX.y * 0.3) * wobble_strength;
	VERTEX.y += cos(TIME * wobble_speed * 0.7 + VERTEX.x * 0.3) * wobble_strength * 0.5;
}

void fragment() {
	// Sombra
	float a = texture(TEXTURE, UV - shadow_offset * TEXTURE_PIXEL_SIZE).a;
	vec4 shadow = vec4(shadow_color.rgb, shadow_color.a * a);

	vec4 sprite = texture(TEXTURE, UV);
	
	// Flash respetado
	if (COLOR.r > 1.0 || COLOR.g != COLOR.b) {
		sprite.rgb = COLOR.rgb * sprite.a;
	}

	COLOR = mix(shadow, sprite, sprite.a);
}