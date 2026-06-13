shader_type canvas_item;
/**
 * Resolución interna utilizada para pixelar el efecto.
 * Normalmente debería coincidir con la resolución base del juego.
 * Valores menores generan píxeles más grandes.
 */
uniform vec2 pixelation = vec2(256, 256);

/**
 * Primera textura de ruido utilizada para generar la forma base
 * de las nubes, niebla o corrientes de viento.
 */
uniform sampler2D cloud_noise1;

/**
 * Velocidad y dirección de desplazamiento de la primera capa.
 * X controla el movimiento horizontal.
 * Y controla el movimiento vertical.
 */
uniform vec2 scroll_speed1 = vec2(0.02, 0.007);

/**
 * Segunda textura de ruido utilizada para romper patrones repetitivos
 * y añadir más variación visual al efecto.
 */
uniform sampler2D cloud_noise2;

/**
 * Velocidad y dirección de desplazamiento de la segunda capa.
 * Se suele mover en una dirección distinta para obtener un efecto
 * más orgánico.
 */
uniform vec2 scroll_speed2 = vec2(-0.015, -0.004);

/**
 * Punto alrededor del cual el efecto parece curvarse.
 * Se expresa en coordenadas UV (0-1).
 * (0.5, 0.5) = centro de la pantalla.
 * (0.5, 0.0) = centro superior.
 */
uniform vec2 center_pos = vec2(0.5, 0.0);

/**
 * Influencia de la distancia al centro sobre el resultado final.
 * 0.0 = solo ruido.
 * 1.0 = solo gradiente radial.
 * Valores intermedios mezclan ambos efectos.
 */
uniform float position_impact : hint_range(0.0, 1.0, 0.01) = 0.75;

/**
 * Gradiente utilizado para colorear el efecto final.
 * Permite reutilizar el shader para viento, niebla, polvo,
 * polen, hojas, magia, etc. cambiando únicamente la paleta.
 */
uniform sampler2D color_gardient;

void fragment() {
	//The pixelated UV (so that the texture is actually pixelart)
	vec2 pixel_uv = floor(UV * pixelation) / pixelation;
	//Makes sure the clouds aren't stretched, even if it's not square shaped
	vec2 noise_uv_scale = pixel_uv;
	noise_uv_scale.x *= pixelation.x / pixelation.y;
	//The UVs inside the noise texture with time-offset
	vec2 noise1uv = fract(noise_uv_scale + TIME * scroll_speed1);
	vec2 noise2uv = fract(noise_uv_scale + TIME * scroll_speed2);
	//Determents the average color of the two noises
	vec4 noise_col = (texture(cloud_noise1, noise1uv) + texture(cloud_noise2, noise2uv)) * 0.5;
	//The pixels distance to the center
	float dist = distance(pixel_uv, center_pos);
	//Scales the distance to a range between 0 and 1
	vec2 furthest = vec2(-min(sign(center_pos.x - 0.5), 0.0), -min(sign(center_pos.y - 0.5), 0.0));
	float max_dist = distance(center_pos, furthest);
	dist /= max_dist;
	//Mixes the noise color with the distance to get noise that warps around the center
	float final = mix(1.0-noise_col.r, dist, position_impact);
	//applies the color from the gradient
	COLOR = texture(color_gardient, vec2(final, final));
}
