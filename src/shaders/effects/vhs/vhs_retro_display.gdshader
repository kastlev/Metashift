shader_type canvas_item;

// Main texture and parameters
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 10.0) = 3.0;
uniform float vhs_intensity : hint_range(0.0, 10.0) = 3.0;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float opacity : hint_range(0.0, 1.0) = 0.5; 

// Quick & dirty random function
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Keep a clean copy of the screen
    vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // Convert to float to avoid the ivec2/float math crash in Godot 4
    vec2 screen_res = vec2(textureSize(SCREEN_TEXTURE, 0));
    
    // Pixel grid snapping
    vec2 grid_uv = round(SCREEN_UV * (screen_res / pixel_size)) / (screen_res / pixel_size);
    
    // Horizontal glitch - step time to make it chunky, not smooth
    float time_step = floor(TIME * 15.0); 
    float glitch = (random(vec2(time_step, floor(grid_uv.y * 30.0))) - 0.5) * 0.005 * vhs_intensity;
    
    // Tape tracking line - scrolls down the screen
    float tracking_pos = fract(TIME * 0.2); 
    float tracking_line = step(0.95, 1.0 - abs(grid_uv.y - tracking_pos));
    float tracking_glitch = tracking_line * (random(vec2(TIME)) - 0.5) * 0.05;
    
    // Apply all UV offsets at once
    vec2 uv = grid_uv;
    uv.x += glitch + tracking_glitch;

    // Split RGB channels for the color fringe
    float r = texture(SCREEN_TEXTURE, uv + vec2(0.002 * vhs_intensity, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - vec2(0.002 * vhs_intensity, 0.0)).b;
    vec3 vhs_color = vec3(r, g, b);

    // Hard scanlines - follows the pixel grid
    float scanline = mod(floor(SCREEN_UV.y * screen_res.y / pixel_size), 2.0) * 0.15;
    vhs_color -= scanline;

    // Static noise grain
    float noise = (random(uv + floor(TIME * 20.0)) - 0.5) * noise_intensity;
    vhs_color += noise;

    // Final mix - Lerp between clean and VHS look
    vec3 final_color = mix(original_color.rgb, vhs_color, opacity);

    COLOR = vec4(final_color, 1.0);
}