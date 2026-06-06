shader_type canvas_item;

// --- Uniform Parameters ---
uniform float beat_speed : hint_range(0.1, 10.0) = 1.0; 
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.3; 
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5; 
uniform vec3 pulse_color : source_color = vec3(1.0, 0.2, 0.2); 
uniform bool use_glow = true;
uniform bool use_tint = false;

void fragment() {
    // 1. Base color sample
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 2. Generate a sine-based pulse (0..1)
    // The sine function oscillates from -1 to 1. 
    // We remap it to 0 to 1 for a clean pulse effect.
    float pulse = (sin(TIME * beat_speed * 2.0 * PI) * 0.5) + 0.5; 

    // 3. Apply pulse to base brightness (multiplicative effect)
    // brightness starts at 1.0 (rest) and increases by pulse_intensity * pulse
    float brightness = 1.0 + pulse * pulse_intensity;

    vec3 color_out = tex_color.rgb * brightness;

    // 4. Optional glow tint overlay (mixes current color with pulse_color)
    if (use_tint) {
        // Mix amount is proportional to the pulse strength and intensity
        color_out = mix(color_out, pulse_color, pulse * pulse_intensity);
    }

    // 5. Optional glow boost (additive effect)
    if (use_glow) {
        // Adds brightness directly, creating an over-exposed/glowing look
        color_out += pulse * glow_intensity;
    }

    COLOR = vec4(color_out, tex_color.a);
}
