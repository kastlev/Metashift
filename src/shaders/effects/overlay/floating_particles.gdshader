shader_type canvas_item;

/**
 * Color principal del efecto.
 */
uniform vec4 effect_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);

/**
 * Anchura de la dispersión lateral.
 * Valores mayores generan trazos más abiertos.
 */
uniform float width : hint_range(0.0, 1.0) = 0.5;

/**
 * Velocidad de desplazamiento del efecto.
 */
uniform float speed : hint_range(0.0, 10.0) = 0.5;

/**
 * Dirección principal del flujo.
 * (0,1) = abajo
 * (0,-1) = arriba
 * (1,0) = derecha
 * (-1,0) = izquierda
 */
uniform vec2 flow_direction = vec2(0.0, 1.0);

/**
 * Cantidad de capas renderizadas.
 * Más capas = más densidad, pero más coste.
 */
uniform int num_of_layers = 5;

/**
 * Separación entre capas.
 * Afecta el escalado progresivo de cada capa.
 */
uniform float layer_spacing : hint_range(0.0, 2.0) = 0.5;

/**
 * Intensidad de la distorsión lateral.
 */
uniform float distortion_strength : hint_range(0.0, 2.0) = 1.0;

/**
 * Intensidad del efecto de profundidad.
 */
uniform float dof_strength : hint_range(0.0, 10.0) = 5.0;

/**
 * Velocidad de animación de la profundidad.
 */
uniform float dof_speed : hint_range(0.0, 5.0) = 0.1;

/**
 * Semilla utilizada para variar cada capa.
 */
uniform float layer_seed = 7.238917;

/**
 * Brillo inicial acumulado.
 */
uniform float base_brightness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	mat3 p = mat3(
		vec3(13.323122, 23.5112, 21.71123),
		vec3(21.1212, 28.7312, 11.9312),
		vec3(21.8112, 14.7212, 61.3934)
	);

	vec2 uv = SCREEN_UV;

	vec3 acc = vec3(base_brightness);

	float dof = dof_strength * sin(TIME * dof_speed);

	for (int i = 0; i < num_of_layers; i++) {
		float fi = float(i);

		vec2 q = uv * (1.0 + fi * layer_spacing);

		vec2 flow_offset =
			flow_direction *
			(speed * TIME / (1.0 + fi * layer_spacing * 0.03));

		vec2 distortion =
			vec2(
				q.y *
				(width * mod(fi * layer_seed, 1.0) - width * 0.5) *
				distortion_strength,
				0.0
			);

		q += flow_offset + distortion;

		vec3 n = vec3(floor(q), 31.189 + fi);
		vec3 m = floor(n) * 0.00001 + fract(n);
		vec3 mp = (31415.9 + m) / fract(p * m);
		vec3 r = fract(mp);

		vec2 s = abs(mod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);

		s += 0.01 * abs(2.0 * fract(10.0 * q.yx) - 1.0);

		float d =
			0.6 * max(s.x - s.y, s.x + s.y)
			+ max(s.x, s.y)
			- 0.01;

		float edge =
			0.005 +
			0.05 *
			min(
				0.5 * abs(fi - 5.0 - dof),
				1.0
			);

		acc += vec3(
			smoothstep(edge, -edge, d) *
			(r.x / (1.0 + 0.02 * fi * layer_spacing))
		);
	}

	float alpha = clamp(length(acc), 0.0, 1.0);

	COLOR.rgb = acc * effect_color.rgb;
	COLOR.a = alpha * effect_color.a;
}