shader_type canvas_item;

/* Velocidad base del desplazamiento */
uniform float scroll_speed: hint_range(0.0, 2.0) = 0.3;

/* Offset acumulado — se actualiza desde GDScript cada frame */
uniform vec2 scroll_offset = vec2(0.0, 0.0);


void fragment() {
    vec2 uv = fract(UV + scroll_offset);
    COLOR = texture(TEXTURE, uv);
}