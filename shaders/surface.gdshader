shader_type spatial;
render_mode unshaded, cull_disabled;
// The water's surface seen from below: bright sky light straight overhead (Snell's window, about 49
// degrees from straight up), and outside it the dim blue of the water mirrored back. Ripples are the
// caustics picture drifting in two layers, bending the window's edge and lighting the wave crests.

uniform sampler2D ripple_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 deep : source_color = vec3(0.08, 0.36, 0.52);
uniform vec3 bright : source_color = vec3(0.78, 0.96, 1.0);
// Metres one ripple pattern covers (main.gd sets it from the size of the biggest animal).
uniform float ripple_size = 3.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz / ripple_size;
	float r1 = texture(ripple_tex, p + vec2(TIME * 0.05, TIME * 0.03)).r;
	float r2 = texture(ripple_tex, p * 0.71 + vec2(-TIME * 0.04, TIME * 0.035)).r;
	float r = (r1 + r2) * 0.5;
	vec3 view = normalize(wpos - CAMERA_POSITION_WORLD);
	float up = clamp(view.y, 0.0, 1.0) + (r - 0.4) * 0.18;
	float window = smoothstep(0.58, 0.8, up);
	ALBEDO = mix(deep, bright, window) + bright * r * (0.25 + 0.35 * window);
}
