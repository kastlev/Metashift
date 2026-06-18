shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

/* Mip level usado al samplear el screen texture para extraer el glow.
   Mips más altos = blur más amplio y más barato. */
uniform float glow_mip_level : hint_range(0.0, 6.0) = 2.0;

/* Umbral de brillo: solo el color que supera este valor se considera
   "glow". Subir esto reduce qué tan fácil brilla algo. */
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.25;

/* Cuántos texeles de distancia se samplean para difuminar el glow
   en cada dirección (arriba/abajo/izquierda/derecha). */
uniform float glow_spread : hint_range(0.0, 8.0) = 1.0;

/* Intensidad final del glow aplicado sobre la imagen original. */
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;


float czm_luminance(vec3 rgb)
{
	// Algorithm from Chapter 10 of Graphics Shaders.
	const vec3 W = vec3(0.2125, 0.7154, 0.0721);
	return dot(rgb, W);
}

vec3 get_glow(sampler2D text, vec2 uv)
{
	return max(textureLod(text, uv, glow_mip_level).rgb - glow_threshold, vec3(0.0));
}

void fragment()
{
	vec2 pixel_size = SCREEN_PIXEL_SIZE * glow_spread;
	vec3 color_screen = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	vec3 glow_x_right = get_glow(SCREEN_TEXTURE, SCREEN_UV + vec2(pixel_size.x, 0.0));
	vec3 glow_x_left = get_glow(SCREEN_TEXTURE, SCREEN_UV + vec2(-pixel_size.x, 0.0));
	vec3 glow_y_top = get_glow(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -pixel_size.y));
	vec3 glow_y_bottom = get_glow(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, pixel_size.y));

	vec3 final_glow = (glow_x_right + glow_x_left + glow_y_top + glow_y_bottom) * 0.25;

	float lum = czm_luminance(color_screen);
	COLOR.rgb = color_screen + (final_glow * lum * glow_intensity);
}