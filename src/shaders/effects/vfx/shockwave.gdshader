shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;
uniform vec2 center = vec2(0.5);
uniform float size = 0.2;
uniform float width = 0.1;
uniform float intensity = 0.1;
uniform float chromatic_offset = 0.0;
uniform float alpha: hint_range(0.0, 1.0) = 1.0;
uniform vec4 ring_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float ring_visibility: hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 uv = SCREEN_UV - center;
	float ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= ratio;

	float uv_length = length(uv);
	float ring_mask = smoothstep(size - width, size, uv_length) *
		(1.0 - smoothstep(size, size + width, uv_length));

	vec2 dir = normalize(uv + vec2(0.0001));
	vec2 offset = intensity * ring_mask * -dir;
	float chroma = chromatic_offset * intensity * ring_mask;

	vec4 screen_color = texture(screen_texture, SCREEN_UV + offset);
	screen_color.r = texture(screen_texture, SCREEN_UV + offset + chroma).r;
	screen_color.b = texture(screen_texture, SCREEN_UV + offset - chroma).b;

	vec4 original = texture(screen_texture, SCREEN_UV);

	// 1. mezclar distorsion con original
	vec4 distorted = mix(original, screen_color, alpha * ring_mask);
	// 2. encima agregar el anillo de color
	COLOR = mix(distorted, ring_color, ring_mask * ring_visibility * alpha);
}