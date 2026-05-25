shader_type canvas_item;

// unlit_alpha: opacity in darkness (0.0 = completely hidden, 1.0 = solid black silhouette)
uniform float unlit_alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec3 unlit_color : source_color = vec3(0.0, 0.0, 0.0);
uniform bool is_in_dark = false;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.75;

varying vec4 vertex_color;

// Pseudo-random noise function based on coords and time
float random(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// Store the vertex color (includes node modulate and custom vector draw colors)
	vertex_color = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * vertex_color;
	
	// Default base color in ambient darkness is unlit_color with alpha modulated by unlit_alpha
	vec4 final_color = vec4(unlit_color, tex.a * unlit_alpha);
	
	if (is_in_dark) {
		// Generate an animated noise value using screen coordinates and TIME
		float n = random(FRAGCOORD.xy + vec2(TIME * 15.0));
		
		// Create a dark noise color (varying between pure black and a very dark purple-gray)
		vec3 dark_noise_color = mix(vec3(0.0), vec3(0.08, 0.06, 0.12), n);
		
		// Noise blending factors: overlay opacity fluctuates based on noise
		float overlay_alpha = mix(0.5, 0.9, n);
		
		// Blend the original sprite color with the dark noise color
		vec3 blended_rgb = mix(tex.rgb, dark_noise_color, overlay_alpha * noise_strength);
		
		// Keep the shape visible as a noisy dark entity in the dark (semi-transparent)
		final_color = vec4(blended_rgb, tex.a * mix(0.25, 0.7, n));
	}
	
	COLOR = final_color;
}

void light() {
	vec4 tex = texture(TEXTURE, UV) * vertex_color;
	// Accumulate light contribution to restore the original colors under light.
	// Final color is COLOR + LIGHT. We want:
	// Final = mix(COLOR, tex * LIGHT_COLOR, ATTENUATION)
	// Therefore, LIGHT = (tex * LIGHT_COLOR - COLOR) * ATTENUATION
	//
	// To avoid compiler syntax/translation issues on D3D12/WebGL,
	// we decompose the vec4 fields explicitly into four float arguments.
	vec3 rgb_part = (tex.rgb * LIGHT_COLOR.rgb * LIGHT_COLOR.a - COLOR.rgb) * ATTENUATION;
	float alpha_part = (tex.a - COLOR.a) * ATTENUATION;
	
	LIGHT = vec4(rgb_part.r, rgb_part.g, rgb_part.b, alpha_part);
}
