shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 2.0) = 0.5; // 0.5
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.75; // 0.838
uniform float grain_strength : hint_range(0.0, 1.0) = 0.04; // 0.132
uniform float grain_speed : hint_range(0.0, 10.0) = 3.0; // 10.0

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV - 0.5;
	
	// Viñeta
	float dist = length(uv);
	float vignette = smoothstep(vignette_radius, vignette_radius - 0.3, dist);
	vignette = 1.0 - (1.0 - vignette) * vignette_strength;
	
	// Grain animado
	float grain = random(UV + fract(TIME * grain_speed)) * grain_strength;
	
	COLOR = vec4(vec3(grain), 1.0 - vignette);
}