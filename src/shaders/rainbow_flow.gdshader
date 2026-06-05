shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0) = 1.0;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float hue = (UV.x + UV.y) * 0.25 + mod(TIME * 0.5, 1.0);
	COLOR.rgb *= hsv2rgb(vec3(hue, 0.6, 1.0));
	COLOR.a *= alpha;
}
