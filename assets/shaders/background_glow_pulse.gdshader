shader_type canvas_item;

uniform float pulse_speed = 1.35;
uniform float pulse_strength = 0.34;
uniform float glow_threshold = 0.34;
uniform float wind_strength = 0.0;
uniform float wind_speed = 0.85;

void fragment() {
	vec4 base_texel = texture(TEXTURE, UV);
	float base_brightest = max(base_texel.r, max(base_texel.g, base_texel.b));
	float green_bias = base_texel.g - max(base_texel.r, base_texel.b);
	float foliage_mask = smoothstep(0.02, 0.18, green_bias) * smoothstep(0.05, 0.55, base_brightest) * (1.0 - smoothstep(0.62, 0.92, base_brightest));

	float wave = sin((UV.y * 22.0) + (TIME * wind_speed)) + sin((UV.y * 41.0) + (TIME * wind_speed * 1.37));
	vec2 wind_uv = UV + vec2(wave * wind_strength * foliage_mask, 0.0);
	vec4 wind_texel = texture(TEXTURE, wind_uv);
	vec4 texel = mix(base_texel, wind_texel, foliage_mask);

	float brightest = max(texel.r, max(texel.g, texel.b));
	float darkest = min(texel.r, min(texel.g, texel.b));
	float saturation = brightest - darkest;

	float blue_glow = smoothstep(0.34, 0.92, texel.b) * smoothstep(0.14, 0.50, saturation);
	float purple_glow = smoothstep(0.34, 0.85, texel.r) * smoothstep(0.34, 0.90, texel.b) * smoothstep(0.12, 0.48, saturation);
	float warm_glow = smoothstep(0.48, 0.96, texel.r) * smoothstep(0.35, 0.90, texel.g) * smoothstep(0.10, 0.45, saturation);
	float bright_glow = smoothstep(0.68, 1.0, brightest) * smoothstep(0.04, 0.30, saturation);

	float blue_mask = blue_glow * smoothstep(glow_threshold, 0.88, brightest);
	float other_glow_mask = max(purple_glow, max(warm_glow, bright_glow)) * smoothstep(0.58, 0.96, brightest);

	float pulse = sin(TIME * pulse_speed);
	float blue_lift = pulse * pulse_strength * blue_mask;
	float soft_lift = pulse * pulse_strength * 0.35 * other_glow_mask;
	vec3 glow_color = mix(texel.rgb, vec3(0.48, 0.86, 1.0), blue_glow * 0.42);
	glow_color = mix(glow_color, vec3(1.0, 0.78, 0.35), warm_glow * 0.12);

	texel.rgb += glow_color * (blue_lift + soft_lift);
	texel.rgb = max(texel.rgb, vec3(0.0));
	COLOR = texel;
}
