shader_type spatial;
render_mode specular_disabled;
// The sand floor: Gulp's painted sand picture (textures/sand.png, from Gulp's textures/land), low dunes
// raised in the mesh, and over it the net of light the waves throw down (textures/caustics.png, the
// picture Gulp's Sea.caustic_texture makes), two layers drifting across one another, as Gulp's floor does.

uniform sampler2D sand_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D caustic_tex : filter_linear_mipmap, repeat_enable;
// Metres of floor one sand picture covers (main.gd sets it from the size of the biggest animal).
uniform float tile = 2.0;
// Metres one mesh of the light's net covers; how bright it is.
uniform float caustic_size = 1.5;
uniform float caustic_strength = 0.9;
uniform vec3 caustic_colour : source_color = vec3(0.75, 0.95, 1.0);
// How high the dunes stand, in the plane's own units (the plane is 1 across before scaling).
uniform float dune_height = 0.0035;

varying vec3 wpos;

float dune(vec2 p) {
	return sin(p.x * 9.0 + sin(p.y * 5.0) * 1.5) * 0.6 + sin(p.y * 13.0 + p.x * 4.0) * 0.4;
}

void vertex() {
	float e = 0.002;
	float h = dune(VERTEX.xz);
	float hx = dune(VERTEX.xz + vec2(e, 0.0));
	float hz = dune(VERTEX.xz + vec2(0.0, e));
	VERTEX.y += h * dune_height;
	NORMAL = normalize(vec3(-(hx - h) / e * dune_height, 1.0, -(hz - h) / e * dune_height));
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 sand = texture(sand_tex, wpos.xz / tile).rgb;
	vec2 p = wpos.xz / caustic_size;
	float c1 = texture(caustic_tex, p + vec2(TIME * 0.03, TIME * 0.02)).r;
	float c2 = texture(caustic_tex, p * 0.77 + vec2(-TIME * 0.024, TIME * 0.017)).r;
	float c = min(c1, c2);
	ALBEDO = sand * 0.85;
	ROUGHNESS = 1.0;
	EMISSION = caustic_colour * sand * c * caustic_strength;
}
