// shadow.gdshader
shader_type canvas_item;

uniform vec2 shadow_offset = vec2(0.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
	float a = texture(TEXTURE, UV - shadow_offset * TEXTURE_PIXEL_SIZE).a;
	vec4 shadow = vec4(shadow_color.rgb, shadow_color.a * a);
	vec4 sprite = texture(TEXTURE, UV);

	if (COLOR.r > 1.0 || COLOR.g != COLOR.b) {
		sprite.rgb = COLOR.rgb * sprite.a;
	}

	COLOR = mix(shadow, sprite, sprite.a);
}