shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float color_levels : hint_range(2.0, 128.0) = 14.0;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.003;
uniform float blur_amount : hint_range(0.0, 2.0) = 0.5;
uniform float brightness : hint_range(0.5, 2.0) = 1.1;
uniform float saturation : hint_range(0.5, 3.0) = 1.2;

uniform float color_offset_multiplier : hint_range(0.0, 0.01) = 0.0008;
uniform float black_offset_multiplier : hint_range(0.0, 0.1) = 0.02;
uniform float color_offset : hint_range(-0.005, 0.005) = 0.001;

float noise(vec2 uv, float offset) {
    return (fract(sin(dot(uv * offset, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
}

vec3 rgb_to_yuv(vec3 rgb) {
    const mat3 RGB_TO_YUV = mat3(
        vec3(0.299, 0.587, 0.114),
        vec3(-0.14713, -0.28886, 0.436),
        vec3(0.615, -0.51499, -0.10001)
    );
    return rgb * RGB_TO_YUV;
}

vec3 yuv_to_rgb(vec3 yuv) {
    const mat3 YUV_TO_RGB = mat3(
        vec3(1.0, 0.0, 1.13983),
        vec3(1.0, -0.39465, -0.58060),
        vec3(1.0, 2.03211, 0.0)
    );
    return clamp(yuv * YUV_TO_RGB, vec3(0.0), vec3(1.0));
}

void fragment() {
    vec2 uv = SCREEN_UV;

    float line_logic = uv.y * 487.0;
    vec2 noise_coord = vec2(floor(line_logic), fract(line_logic));

    // Offsets mucho más pequeños para no deformar
    float x_offset = color_offset + noise(noise_coord, TIME) * color_offset_multiplier;
    float black_offset = noise(noise_coord, TIME + 65.0) * (black_offset_multiplier * 0.005);

    vec3 col;
    col.r = texture(SCREEN_TEXTURE, uv + vec2(chromatic_aberration + black_offset, 0.0)).r;
    col.g = texture(SCREEN_TEXTURE, uv + vec2(black_offset, 0.0)).g;
    col.b = texture(SCREEN_TEXTURE, uv - vec2(chromatic_aberration - black_offset, 0.0)).b;

    vec4 color_shifted = textureLod(SCREEN_TEXTURE, uv + vec2(x_offset, 0.0), blur_amount * 0.15);
    vec3 yuv_base = rgb_to_yuv(col);
    vec3 yuv_chroma = rgb_to_yuv(color_shifted.rgb);

    col = yuv_to_rgb(vec3(yuv_base.x, yuv_chroma.yz));

    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, saturation);
    col *= brightness;

    col.rgb = floor(col.rgb * color_levels + 0.3) / color_levels;

    col = clamp(col, 0.0, 1.0);
    col = mix(col, col * col * (3.0 - 2.0 * col), 0.5);

    COLOR = vec4(col, 1.0);
}