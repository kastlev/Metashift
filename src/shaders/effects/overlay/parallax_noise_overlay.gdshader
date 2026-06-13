shader_type canvas_item;
render_mode blend_mix;

/**
 * Posición global de la cámara.
 * Se utiliza para que la niebla permanezca fija en el mundo
 * en lugar de seguir la pantalla.
 */
uniform vec2 camera_position;

/**
 * Offset actual de la cámara.
 * Permite que efectos como screen shake afecten también
 * a la niebla.
 */
uniform vec2 camera_offset;

/**
 * Influencia del movimiento de la cámara sobre el patrón.
 */
uniform float camera_position_speed : hint_range(0.0, 1.0) = 0.025;

/**
 * Influencia del offset de la cámara sobre el patrón.
 */
uniform float camera_offset_speed : hint_range(0.0, 1.0) = 0.025;

/**
 * Textura de ruido utilizada para generar la niebla.
 * Debe estar configurada como repeat.
 */
uniform sampler2D noise_texture : repeat_enable;

/**
 * Velocidad de desplazamiento del ruido.
 */
uniform float noise_speed : hint_range(0.0, 1.0) = 1.0;

/**
 * Dirección de movimiento del ruido.
 */
uniform vec2 noise_dir = vec2(1.0, -1.0);

/**
 * Color de la niebla.
 */
uniform vec3 smoke_color : source_color = vec3(0.8);

/**
 * Intensidad global del efecto.
 */
uniform float density : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 offset =
		(camera_position * camera_position_speed) +
		(camera_offset * camera_offset_speed);

	vec2 time_offset =
		TIME * noise_dir * noise_speed * 0.1;

	vec2 distorted_uv =
		UV +
		time_offset +
		vec2(offset.x, offset.y * 1.75) * 0.1;

	float noise =
		texture(noise_texture, distorted_uv).r;

	float smoke_alpha =
		noise * density;

	COLOR = vec4(smoke_color, smoke_alpha);
}