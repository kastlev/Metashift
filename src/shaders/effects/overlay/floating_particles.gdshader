shader_type canvas_item;

uniform vec4 effect_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform float width : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.0, 10.0) = 0.5;
uniform int num_of_layers = 5;

void fragment() {
	mat3 p = mat3(
		vec3(13.323122,23.5112,21.71123),
		vec3(21.1212,28.7312,11.9312),
		vec3(21.8112,14.7212,61.3934)
	);

	vec2 uv = SCREEN_UV;
	vec3 acc = vec3(0.1);
	float dof = 5.0 * sin(TIME * 0.1);

	for (int i = 0; i < num_of_layers; i++) {
		float fi = float(i);

		vec2 q = uv * (1.0 + fi * 0.5);
		q += vec2(
			q.y * (width * mod(fi * 7.238917, 1.0) - width * 0.5),
			speed * TIME / (1.0 + fi * 0.5 * 0.03)
		);

		vec3 n = vec3(floor(q), 31.189 + fi);
		vec3 m = floor(n) * 0.00001 + fract(n);
		vec3 mp = (31415.9 + m) / fract(p * m);
		vec3 r = fract(mp);

		vec2 s = abs(mod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);
		s += 0.01 * abs(2.0 * fract(10.0 * q.yx) - 1.0);

		float d = 0.6 * max(s.x - s.y, s.x + s.y) + max(s.x, s.y) - 0.01;
		float edge = 0.005 + 0.05 * min(0.5 * abs(fi - 5.0 - dof), 1.0);

		acc += vec3(
			smoothstep(edge, -edge, d) *
			(r.x / (1.0 + 0.02 * fi * 0.5))
		);
	}

	float alpha = clamp(length(acc), 0.0, 1.0);

	COLOR.rgb = acc * effect_color.rgb;
	COLOR.a = alpha * effect_color.a;
}