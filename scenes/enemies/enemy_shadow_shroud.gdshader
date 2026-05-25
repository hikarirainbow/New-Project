shader_type canvas_item;

// unlit_alpha: opacity in darkness (0.0 = completely hidden, 1.0 = solid black silhouette)
uniform float unlit_alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec3 unlit_color : source_color = vec3(0.0, 0.0, 0.0);

varying vec4 vertex_color;

void vertex() {
	// Store the vertex color (includes node modulate and custom vector draw colors)
	vertex_color = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * vertex_color;
	// Default base color in ambient darkness is unlit_color with alpha modulated by unlit_alpha
	COLOR = vec4(unlit_color, tex.a * unlit_alpha);
}

void light() {
	vec4 tex = texture(TEXTURE, UV) * vertex_color;
	// Accumulate light contribution to restore the original colors under light.
	// Final color is COLOR + LIGHT. We want:
	// Final = mix(unlit_color, tex * LIGHT_COLOR, ATTENUATION)
	// Therefore, LIGHT = (tex * LIGHT_COLOR - unlit_color) * ATTENUATION
	LIGHT = vec4(
		(tex.rgb * LIGHT_COLOR.rgb * LIGHT_COLOR.a - unlit_color) * ATTENUATION,
		(tex.a - tex.a * unlit_alpha) * ATTENUATION
	);
}
