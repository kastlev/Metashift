shader_type canvas_item;

/* Hit effect */
uniform bool get_hit = false;

/* Tint */
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

/* Shake */
uniform float shake_intensity : hint_range(0.0, 20.0) = 10.0;
uniform float shake_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shake_speed : hint_range(0.0, 60.0) = 30.0;

/* Flash */
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform float flash_speed : hint_range(0.0, 60.0) = 30.0;
uniform bool flash_solid = true;

/* Wind effect */
uniform bool render_noise = false;
uniform sampler2D noise_texture : repeat_enable;
uniform float amplitude : hint_range(0.0, 0.5, 0.01) = 0.0;
uniform float time_scale : hint_range(0.0, 5.0, 0.01) = 0.04;
uniform float noise_scale : hint_range(0.0, 2.0, 0.0001) = 0.001;
uniform float rotation_strength : hint_range(0.0, 5.0, 0.1) = 1.0;
uniform vec2 rotation_pivot = vec2(0.5, 1.0);

varying vec2 world_position;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;

	if (get_hit && shake_strength > 0.0) {
		float time = TIME * shake_speed;
		vec2 random_offset = vec2(
			rand(vec2(time, 0.0)) * 2.0 - 1.0,
			rand(vec2(time, 10.0)) * 2.0 - 1.0
		);

		VERTEX += random_offset * shake_intensity * shake_strength;
	}
}

vec2 get_sample_pos(vec2 pos, float scale, float offset) {
	pos *= scale;
	pos += offset;
	return pos;
}

vec2 rotate_vec(vec2 v, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	v -= pivot;
	return vec2(
		cosa * v.x - sina * v.y,
		cosa * v.y + sina * v.x
	) + pivot;
}

void fragment() {
	vec2 noise_sample_pos = get_sample_pos(world_position, noise_scale, TIME * time_scale);
	float noise_amount = texture(noise_texture, noise_sample_pos).r - 0.5;
	float rotation = amplitude * noise_amount;

	vec2 rotated_uvs = rotate_vec(UV, rotation_pivot, rotation);
	float dist = distance(UV, rotation_pivot) * rotation_strength;
	vec2 result_uvs = mix(UV, rotated_uvs, dist);

	vec4 final_color = texture(TEXTURE, result_uvs);

	final_color.rgb *= tint_color.rgb;
	final_color.a *= tint_color.a * opacity;

	if (get_hit && flash_strength > 0.0) {
		float flash = flash_solid ? 1.0 : sin(TIME * flash_speed) * 0.5 + 0.5;
		float intensity = flash * flash_strength * final_color.a;
		final_color.rgb = mix(final_color.rgb, flash_color.rgb, intensity);
	}

	if (render_noise) {
		final_color = texture(noise_texture, noise_sample_pos);
	}

	COLOR = final_color;
}