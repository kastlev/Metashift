shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

// Ángulo de los rayos — negativo inclina a la izquierda
uniform float angle = -0.2;      
// Posición horizontal del origen
uniform float position = -0.1;
// Cuánto se abren los rayos hacia abajo
uniform float spread : hint_range(0.0, 1.0) = 0.15;
// Corte de los bordes laterales
uniform float cutoff : hint_range(-1.0, 1.0) = 0.15;
// Suavizado del borde inferior
uniform float falloff : hint_range(0.0, 1.0) = 0.6;
// Suavizado de los bordes laterales
uniform float edge_fade : hint_range(0.0, 1.0) = 0.12;
// Desplazamiento vertical — positivo = sube los rayos, negativo = baja
uniform float vertical_offset : hint_range(-1.0, 1.0) = -0.3;
// Velocidad de animación — lento = atmosférico
uniform float speed = 0.4;
// Rayos gruesos — pocos y anchos
uniform float ray1_density = 5.0;
// Rayos finos — textura de fondo
uniform float ray2_density = 20.0;
// Intensidad de los rayos finos
uniform float ray2_intensity : hint_range(0.0, 1.0) = 0.2;
// Color — verde amarillento, evoca luz filtrada por vegetación/laboratorio
uniform vec4 color : source_color = vec4(0.75, 0.9, 0.4, 0.25);
// Sin HDR — más controlado con pixel art
uniform bool hdr = false;
uniform float seed = 5.0;
float random(vec2 _uv) {
	return fract(sin(dot(_uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) +
		(c - a) * u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

mat2 rotate(float _angle) {
	return mat2(vec2(cos(_angle), -sin(_angle)),
				vec2(sin(_angle), cos(_angle)));
}

vec4 screen(vec4 base, vec4 blend) {
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment() {
	vec2 transformed_uv = (rotate(angle) * (UV - position)) / ((UV.y + spread) - (UV.y * spread));

	vec2 ray1 = vec2(transformed_uv.x * ray1_density + sin(TIME * 0.1 * speed) * (ray1_density * 0.2) + seed, 1.0);
	vec2 ray2 = vec2(transformed_uv.x * ray2_density + sin(TIME * 0.2 * speed) * (ray1_density * 0.2) + seed, 1.0);

	float cut = step(cutoff, transformed_uv.x) * step(cutoff, 1.0 - transformed_uv.x);
	ray1 *= cut;
	ray2 *= cut;

	float rays;
	if (hdr) {
		rays = noise(ray1) + (noise(ray2) * ray2_intensity);
	} else {
		rays = clamp(noise(ray1) + (noise(ray2) * ray2_intensity), 0.0, 1.0);
	}

	rays *= smoothstep(0.0, falloff, (1.0 - UV.y + vertical_offset));
	rays *= smoothstep(0.0 + cutoff, edge_fade + cutoff, transformed_uv.x);
	rays *= smoothstep(0.0 + cutoff, edge_fade + cutoff, 1.0 - transformed_uv.x);

	vec3 shine = vec3(rays) * color.rgb;
	// Screen blend corregido para Godot 4
	shine = screen(texture(SCREEN_TEXTURE, SCREEN_UV), vec4(color)).rgb;

	COLOR = vec4(shine, rays * color.a);
}