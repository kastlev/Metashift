// This shader creates a pixel-snapped dissolve effect, where pixels randomly
// appear and disappear based on a noise threshold driven by `progress`.
// Animate `progress` via Tween (0.0 = fully visible, 1.0 = fully dissolved)
// to control the disintegration manually instead of relying on a fixed oscillation.
shader_type canvas_item;
render_mode unshaded;

/* Progreso del dissolve (0.0 a 1.0). Anímalo con un Tween:
   0.0 = sprite completamente visible, 1.0 = completamente disuelto. */
uniform float progress : hint_range(0.0, 1.0) = 0.5;

/* Escala del patrón de ruido. A mayor valor, ruido más fino;
   a menor valor, parches más grandes de pixeles visibles/invisibles. */
uniform float noise_scale : hint_range(0.1, 4.0) = 1.0;

// Function to generate pseudo-random values
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 438.5453);
}

void fragment() {
	// Get the size of the texture
	float size_x = float(textureSize(TEXTURE, 0).x);
	float size_y = float(textureSize(TEXTURE, 0).y);

	// Fetch the original pixel color from the texture
	vec4 pixel_color = texture(TEXTURE, UV);

	// Calculate UV coordinate snapped to pixel grid, scaled by noise_scale
	vec2 uv_snapped = vec2(
		floor(UV.x * size_x * noise_scale) / (size_x * noise_scale),
		floor(UV.y * size_y * noise_scale) / (size_y * noise_scale)
	);

	// Calculate visibility based on a random threshold driven by progress
	float visible = step(progress, random(uv_snapped));

	// Output final color with modified alpha based on visibility and original pixel alpha
	COLOR = vec4(pixel_color.r, pixel_color.g, pixel_color.b, min(visible, pixel_color.a));
}