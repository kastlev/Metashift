shader_type canvas_item;

// هذا السطر هو الأهم، هو الذي يسحب صورة اللعبة ليعالجها
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float line_count : hint_range(1.0, 100.0) = 40.0;
uniform float line_density : hint_range(0.0, 1.0) = 0.4;
uniform float line_speed : hint_range(0.0, 20.0) = 8.0;
uniform float line_falloff : hint_range(0.0, 1.0) = 0.3;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 centered_uv = uv - vec2(0.5);

    // تصحيح الأبعاد لضمان أن الدائرة لا تصبح بيضاوية في الشاشات العريضة
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    centered_uv.x /= aspect;

    float angle = atan(centered_uv.y, centered_uv.x);
    float dist = length(centered_uv);

    float n = hash(floor(angle * line_count));
    float thickness = abs(sin(angle * line_count + n));

    float speed = TIME * line_speed * (0.5 + n);
    float lines = step(line_density, fract(thickness + speed));

    float mask = smoothstep(line_falloff, line_falloff + 0.2, dist);
    float final_effect = lines * mask * line_color.a;

    // جلب لون المشهد الحقيقي
    vec4 screen_col = texture(screen_texture, uv);

    // دمج الخطوط مع المشهد
    vec3 mixed_color = mix(screen_col.rgb, line_color.rgb, final_effect);

    COLOR = vec4(mixed_color, 1.0);
}