shader_type canvas_item;

uniform vec4 base_color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float magnification_factor = 2.0;
uniform float pulse_frequency : hint_range(0.2, 5.0) = 0.7;
uniform float flex_amplitude : hint_range(0.0, 1.5) = 0.05;
uniform float saturation_point : hint_range(0.0, 2.0) = 0.1;
uniform float phase_offset : hint_range(-3.14, 3.14) = 0.0;
uniform float decay_exponent : hint_range(0.0, 10.0) = 2.0;
uniform float onset_delay : hint_range(0.0, 1.0) = 0.1;

void vertex() {
    VERTEX = VERTEX * magnification_factor;
}

void fragment() {
    vec2 area_pos = REGION_RECT.xy;
    vec2 area_size = REGION_RECT.zw;
    
    vec2 proj_coord = (UV - area_pos) / area_size * magnification_factor;
    proj_coord -= (magnification_factor - 1.0) / magnification_factor;
    
    float depth_inv = 1.0 - proj_coord.y;
    float curvature = pow(depth_inv, decay_exponent);
    
    float intensity_mask = smoothstep(onset_delay * curvature, saturation_point, depth_inv);
    float oscillation = sin((TIME * pulse_frequency) + phase_offset);
    
    proj_coord.x += oscillation * curvature * intensity_mask * flex_amplitude;
    
    vec2 edge_bounds = step(vec2(0.0), proj_coord) * step(proj_coord, vec2(1.0));
    
    vec4 pixel_data = texture(TEXTURE, (proj_coord * area_size) + area_pos);
    COLOR = pixel_data * base_color_tint;
    COLOR.a *= edge_bounds.x * edge_bounds.y;
}