shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

/// Intensidad del grano (0 = sin grano)
uniform float grain_amount : hint_range(0.0, 1.0) = 0.05;
/// Tamaño del grano
uniform float grain_size : hint_range(0.1, 10.0) = 1.0;
/// Velocidad de animación del grano (0 = estático)
uniform float speed : hint_range(0.0, 5.0) = 1.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 screen = texture(screen_texture, SCREEN_UV);

	// UV animado — si speed = 0 el grano es estático
	vec2 animated_uv = UV + TIME * speed;
	float noise = (random(animated_uv) - 0.5) * 2.0;

	screen.rgb += noise * grain_amount * grain_size;

	COLOR = clamp(screen, 0.0, 1.0);
}