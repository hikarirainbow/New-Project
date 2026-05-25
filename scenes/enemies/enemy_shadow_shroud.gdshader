shader_type canvas_item;

// light_threshold: the threshold for the light edge. 
// A very low value ensures that even faint light reveals the colors.
uniform float light_threshold : hint_range(0.0, 1.0) = 0.05;

varying vec4 vertex_color;

void vertex() {
	// Cache the vertex colors (includes modulate and custom _draw colors)
	vertex_color = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	// By default (in ambient darkness), render the sprite as a solid black silhouette
	COLOR = vec4(0.0, 0.0, 0.0, tex.a);
}

void light() {
	vec4 tex = texture(TEXTURE, UV) * vertex_color;
	
	// Use LIGHT_COLOR.a directly to create a smooth, radiant gradient transition at the vision edge.
	// LIGHT_COLOR.a represents the light's radial falloff and shadow intensity.
	vec3 rgb_part = tex.rgb * LIGHT_COLOR.rgb * LIGHT_COLOR.a;
	
	LIGHT = vec4(rgb_part.r, rgb_part.g, rgb_part.b, 0.0);
}
