// This shader creates a procedural noise effect using a combination of Perlin noise and
// fractal Brownian motion (fbm). It generates a noise pattern that evolves over time and
// applies a checkerboard effect to the rotation of the noise coordinates. The resulting
// noise is used to distort the screen texture, creating a dynamic visual effect.

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

/* Resolución de referencia usada para normalizar FRAGCOORD a UV.
   Debe coincidir con la resolución base del viewport para que el
   patrón de ruido no se estire ni se comprima. */
uniform vec2 reference_resolution = vec2(1920.0, 1080.0);

/* Velocidad con la que el ruido evoluciona en el tiempo (animación). */
uniform float noise_time_speed : hint_range(0.0, 0.1) = 0.015;

/* Fuerza de la distorsión aplicada a la textura de pantalla.
   A mayor valor, más se desplazan los píxeles según el gradiente del ruido. */
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.008;

/* --- Parámetros de fbm --- */

/* Amplitud inicial de la primera octava de ruido. */
uniform float fbm_initial_amplitude : hint_range(0.0, 1.0) = 0.2;

/* Frecuencia inicial de la primera octava de ruido. */
uniform float fbm_initial_frequency : hint_range(0.0, 10.0) = 2.8;

/* Velocidad de rotación inicial aplicada a las coordenadas de ruido por octava. */
uniform float fbm_initial_rotation_speed : hint_range(0.0, 1.0) = 0.01;

/* Cuánto se multiplica la amplitud en cada octava sucesiva (decaimiento). */
uniform float fbm_amplitude_falloff : hint_range(0.0, 1.0) = 0.7;

/* Cuánto se multiplica la frecuencia en cada octava sucesiva (detalle). */
uniform float fbm_frequency_growth : hint_range(1.0, 4.0) = 1.8;

/* Cuánto se multiplica la velocidad de rotación en cada octava sucesiva. */
uniform float fbm_rotation_falloff : hint_range(0.0, 1.0) = 0.7;

/* Número de octavas de ruido acumuladas. Más octavas = más detalle, más costo. */
uniform int fbm_octaves : hint_range(1, 8) = 6;

/* Cuánto influye el gradiente acumulado de octavas anteriores en la
   posición de muestreo de la siguiente octava (domain warping). */
uniform float fbm_gradient_warp : hint_range(0.0, 1.0) = 0.4;

#define PI 3.14159265359
#define CHECKERED

// Function to create a 2x2 rotation matrix for rotating a vector by a given angle
mat2 rot(float angle) {
	return mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
}

// Function to create a checkerboard pattern
float checkersign(vec2 uv) {
#ifdef CHECKERED
	uv = floor(uv);
	return sign(mod(uv.x + uv.y, 2.0) - 0.5);
#else
	return 1.0;
#endif
}

// Helper functions for Perlin noise calculations
vec3 v3mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 v4mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return v4mod289(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
	return 1.79284291400159 - 0.85373472095314 * r;
}

// Function to generate simplex noise and its gradient
float snoise(vec3 v, out vec3 gradient, float time) {
	const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
	vec3 i = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;
	i = v3mod289(i);
	vec4 p = permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0)) + i.y + vec4(0.0, i1.y, i2.y, 1.0)) + i.x + vec4(0.0, i1.x, i2.x, 1.0));
	float n_ = 0.142857142857;
	vec3 ns = n_ * D.wyz - D.xzx;
	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);
	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);
	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);
	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));
	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);
	vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;
	x0.xy *= rot(time * checkersign(a0.xy));
	x1.xy *= rot(time * checkersign(a0.zw));
	x2.xy *= rot(time * checkersign(a1.xy));
	x3.xy *= rot(time * checkersign(a1.zw));
	vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	vec4 m2 = m * m;
	vec4 m4 = m2 * m2;
	vec4 pdotx = vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3));
	vec4 temp = m2 * m * pdotx;
	gradient = -8.0 * (temp.x * x0 + temp.y * x1 + temp.z * x2 + temp.w * x3);
	gradient += m4.x * p0 + m4.y * p1 + m4.z * p2 + m4.w * p3;
	gradient *= 42.0;
	return 42.0 * dot(m4, pdotx);
}

// Function to generate fractal Brownian motion (fbm) noise
float fbm(vec3 p, inout vec3 gradient) {
	float value = 0.0;
	float amplitude = fbm_initial_amplitude;
	float frequency = fbm_initial_frequency;
	float rotation = fbm_initial_rotation_speed;
	vec3 grad;
	for (int i = 0; i < fbm_octaves; i++) {
		value += amplitude * snoise(frequency * p - gradient * fbm_gradient_warp, grad, TIME * rotation);
		gradient += amplitude * grad;
		frequency *= fbm_frequency_growth;
		amplitude *= fbm_amplitude_falloff;
		rotation *= fbm_rotation_falloff;
	}
	return value;
}

// Main fragment function to apply the procedural noise effect
void fragment() {
	vec2 uv = FRAGCOORD.xy / reference_resolution;
	vec3 p = vec3(uv, 0.0);
	vec3 gradient = vec3(0.0);
	float noise = fbm(p + vec3(0.0, 0.0, TIME * noise_time_speed), gradient);
	noise = noise * 0.5 + 0.5;
	vec3 background = texture(screen_texture, uv + gradient.xy * distortion_strength).rgb;
	vec3 col = background;
	COLOR = vec4(col, 1.0);
}