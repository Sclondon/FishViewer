// The family shaders' fragment (GameCommon `godot/motion-families`): the animal's baked paint
// (GameCommon `godot/baked-look`), its glow where it has one; where the bake cut the back of the mouth
// away (alpha under a half) the point is dropped while the mouth is open (or always, for `cut_always`:
// the see-through gaps of a two-sided sheet).

uniform bool cut_always = false;
// A thin light round the animal's outline (a game's own mark: Gulp's FoodMarks lights what the player
// can eat gold and what can eat it red): rgb its colour, a how strong (0, none, as built).
uniform vec4 mark_rim = vec4(0.0);
// A dissolve by distance (a game's own: Gulp's Life fades each animal out before the water hides it and it stops
// being drawn): metres from the eye to the animal where it fades in, from x to y, and out, from z to w; left alone,
// nothing fades. Dithered on one screen pattern (as sea-floor-props' rock and soft shaders' `lod_band`).
instance uniform vec4 lod_band = vec4(-2.0, -1.0, 1.0e9, 1.0e9);

void fragment() {
	{
		float lod_gap = length(CAMERA_POSITION_WORLD - NODE_POSITION_WORLD);
		float lod_grain = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (lod_grain >= 1.0 - smoothstep(lod_band.z, lod_band.w, lod_gap) || lod_grain < 1.0 - smoothstep(lod_band.x, lod_band.y, lod_gap)) {
			discard;
		}
	}
	// (a sharper mipmap than the usual: the markings were drawn per pixel, sharp, before)
	vec4 paint = texture(baked_paint, bake_uv, -1.0);
#ifdef MOTION_SHEER
	ALPHA = paint.a;
#else
	if (paint.a < 0.5 && (gape > 0.0 || cut_always)) {
		discard;
	}
#endif
	ALBEDO = paint.rgb;
	EMISSION = texture(baked_glow, bake_uv).rgb * baked_glow_scale;
	// (the mark: brightest where the surface turns away from the eye, nothing face on)
	float edge = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	EMISSION += mark_rim.rgb * (mark_rim.a * smoothstep(0.25, 0.85, edge));
	ROUGHNESS = baked_roughness;
	SPECULAR = baked_specular;
}
