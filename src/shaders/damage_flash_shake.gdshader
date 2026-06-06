shader_type canvas_item;

// Variable for hit effect
uniform bool get_hit = false;
uniform float hit_effect : hint_range(0,1) = 0.0;
uniform float shake_intensity = 10.0;
uniform float flash_speed = 30.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

// Variable for wind effect
uniform bool render_noise = false;
uniform sampler2D noise_texture : repeat_enable; // set in inspector
uniform float amplitude : hint_range(0.0, 0.5, 0.01) = 0.05;
uniform float time_scale : hint_range(0.0, 5.0, 0.01) = 0.04;
uniform float noise_scale : hint_range(0.0, 2.0, 0.0001) = 0.001;
uniform float rotation_strength : hint_range(0.0, 5.0, 0.1) = 1;
uniform vec2 rotation_pivot = vec2(0.5, 1);
varying vec2 world_position;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void vertex(){
	if(get_hit){
		float time = TIME * 30.0;
        vec2 random_offset = vec2(
            rand(vec2(time, 0.0)) * 2.0 - 1.0,
            rand(vec2(time, 10.0)) * 2.0 - 1.0
        );
        VERTEX += random_offset * shake_intensity * hit_effect;
	}
    else{world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;}
}

vec2 get_sample_pos(vec2 pos, float scale, float offset) {
	pos *= scale;
	pos += offset;
	return pos;
}

vec2 rotate_vec(vec2 vec, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	vec -= pivot;
	return vec2(
		cosa * vec.x - sina * vec.y,
		cosa * vec.y + sina * vec.x
	) + pivot;
}

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	// get noise from texture
	vec2 noise_sample_pos = get_sample_pos(world_position, noise_scale, TIME * time_scale);
	float noise_amount = texture(noise_texture, noise_sample_pos).r - 0.5f;

	// get rotation position around a pivot
	float rotation = amplitude * noise_amount;
	vec2 rotated_uvs = rotate_vec(UV, rotation_pivot, rotation);

	// blend original uvs and rotated uvs based on distance to pivot
	float dist = distance(UV, rotation_pivot) * rotation_strength;
	vec2 result_uvs = mix(UV, rotated_uvs, dist);

	// output color
	if (get_hit) {
        float flash = sin(TIME * flash_speed) * 0.5 + 0.5;
        flash *= original_color.a;

        vec4 final_color = mix(original_color, flash_color, flash);
        final_color = mix(original_color, final_color, hit_effect);
        final_color.a = original_color.a;

        COLOR = final_color;
    } else {
       COLOR = texture(TEXTURE, result_uvs);
    }
	// optional, preview noise texture for debugging
	if (render_noise) {
		vec4 noise_color = texture(noise_texture, noise_sample_pos);
		COLOR = noise_color;
	}
}