// Autor: lentsius — godotshaders.com/shader/simple-blur
// Licencia: CC0

shader_type canvas_item;

/* Intensidad del blur (mayor = más borroso, más costoso) */
uniform float lod: hint_range(0.0, 5.0) = 2.0;

/* Tinte de color sobre el blur (útil para oscurecer el menú) */
uniform vec4 tint_color: source_color = vec4(0.0, 0.0, 0.0, 0.3);

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 blurred = textureLod(SCREEN_TEXTURE, SCREEN_UV, lod);
    COLOR = mix(blurred, vec4(tint_color.rgb, 1.0), tint_color.a);
}