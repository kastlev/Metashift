shader_type canvas_item;

uniform int samples = 20;
uniform float blur_amount: hint_range(0.0, 10.0) = 1.0;
uniform vec4 tint_color: source_color = vec4(0.0, 0.0, 0.0, 0.4);
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

float gaussian(float x, float sigma) {
    return exp(-0.5 * (x * x) / (sigma * sigma)) / (sigma * sqrt(6.28318));
}

void fragment() {
    float sigma = float(samples) * 0.25 * blur_amount;
    vec4 result = vec4(0.0);
    float accum = 0.0;
    int half_samples = samples / 2;

    for (int y = -half_samples; y <= half_samples; y++) {
        float weight = gaussian(float(y), sigma);
        vec2 offset = vec2(0.0, float(y) * SCREEN_PIXEL_SIZE.y);
        result += textureLod(screen_texture, SCREEN_UV + offset, 0.0) * weight;
        accum += weight;
    }

    vec4 blurred = result / accum;
    COLOR = mix(blurred, vec4(tint_color.rgb, 1.0), tint_color.a);
}