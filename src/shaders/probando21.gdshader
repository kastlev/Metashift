shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform bool shaking = false;
uniform float amplitude = 1.0;
uniform float noise_scale = 20.0;
uniform float noise_speed = 20.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i + vec2(0.0, 0.0));
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		   (c - a) * u.y * (1.0 - u.x) +
		   (d - b) * u.x * u.y;
}

void fragment() {

	vec2 uv = SCREEN_UV;

	vec4 col = texture(SCREEN_TEXTURE, uv);

	if (shaking) {

		float nx = noise(uv * noise_scale + vec2(TIME * noise_speed, 0.0));
		float ny = noise(uv * noise_scale + vec2(0.0, TIME * noise_speed));

		vec2 dir = normalize(vec2(nx * 2.0 - 1.0, ny * 2.0 - 1.0));

		float n = noise(uv * noise_scale + vec2(TIME * noise_speed));
		float off = (n * 2.0 - 1.0) * amplitude;

		vec2 uv2 = uv + dir * off * SCREEN_PIXEL_SIZE;

		col = texture(SCREEN_TEXTURE, uv2);
	}

	COLOR = col;
}