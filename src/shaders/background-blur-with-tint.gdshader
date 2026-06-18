// Autor: godotshaders.com/shader/background-blur-with-tint
// Licencia: MIT

shader_type canvas_item;
/* Número de samples — más = mejor calida, más lento. Para web: 15-25 */
uniform int samples = 20;

/* LOD de la textura — mayor = más pixelado pero más rápido */
uniform int lod = 2;

/* Tinte sobre el blur */
uniform vec4 tint_color: source_color = vec4(0.0, 0.0, 0.0, 0.4);

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

float gaussian(vec2 i, float sigma) {
    return exp(-0.5 * dot(i /= sigma, i)) / (6.28 * sigma * sigma);
}

vec4 blur(sampler2D tex, vec2 uv, vec2 pixel_size) {
    vec4 result = vec4(0.0);
    float accum = 0.0;
    float sigma = float(samples) * 0.25;
    for (int x = -samples / 2; x <= samples / 2; x++) {
        for (int y = -samples / 2; y <= samples / 2; y++) {
            vec2 offset = vec2(float(x), float(y));
            float weight = gaussian(offset, sigma);
            result += textureLod(tex, uv + pixel_size * offset, float(lod)) * weight;
            accum += weight;
        }
    }
    return result / accum;
}

void fragment() {
    vec4 blurred = blur(screen_texture, SCREEN_UV, SCREEN_PIXEL_SIZE);
    COLOR = mix(blurred, vec4(tint_color.rgb, 1.0), tint_color.a);
}