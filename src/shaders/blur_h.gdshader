shader_type canvas_item;

uniform int samples = 20;
uniform float blur_amount: hint_range(0.0, 10.0) = 1.0;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

float gaussian(float x, float sigma) {
    return exp(-0.5 * (x * x) / (sigma * sigma)) / (sigma * sqrt(6.28318));
}

void fragment() {
    float sigma = float(samples) * 0.25 * blur_amount;
    vec4 result = vec4(0.0);
    float accum = 0.0;
    int half_samples = samples / 2;

    for (int x = -half_samples; x <= half_samples; x++) {
        float weight = gaussian(float(x), sigma);
        vec2 offset = vec2(float(x) * SCREEN_PIXEL_SIZE.x, 0.0);
        result += textureLod(screen_texture, SCREEN_UV + offset, 0.0) * weight;
        accum += weight;
    }

    COLOR = result / accum;
}