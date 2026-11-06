shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D ao_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float edge_softness : hint_range(0.05, 0.45) = 0.15;
uniform float roughness_scale : hint_range(0.0, 1.0) = 0.9;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.45;
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;
uniform float derived_bump : hint_range(0.0, 3.0) = 1.4;
uniform float color_noise_amt : hint_range(0.0, 0.35) = 0.08;
uniform float trail_breakup : hint_range(0.0, 1.0) = 0.0;

vec3 fractal_rgb(sampler2D tex, vec2 uv) {
	return mix(texture(tex, uv).rgb, texture(tex, uv * 0.37).rgb, 0.4);
}

float fractal_r(sampler2D tex, vec2 uv) {
	return mix(texture(tex, uv).r, texture(tex, uv * 0.37).r, 0.4);
}

void fragment() {
	vec2 uv = UV;
	vec3 alb = fractal_rgb(albedo_tex, uv);
	float n = texture(noise_tex, uv * vec2(0.18, 0.12)).r;
	alb *= 1.0 + (n - 0.5) * color_noise_amt * 2.0;
	ALBEDO = alb * albedo_tint.rgb;

	vec3 nmap = mix(texture(normal_tex, uv).rgb, texture(normal_tex, uv * 0.37).rgb, 0.4);
	float map_amt = clamp(length(nmap - vec3(0.5, 0.5, 1.0)) * 4.0, 0.0, 1.0);
	NORMAL_MAP = nmap;
	NORMAL_MAP_DEPTH = normal_scale * map_amt;

	float lum = dot(alb, vec3(0.299, 0.587, 0.114));
	vec3 bump = vec3(-dFdx(lum), -dFdy(lum), 0.0) * derived_bump * 14.0;
	NORMAL = normalize(NORMAL + bump * (1.0 - map_amt * 0.65));

	float r = fractal_r(roughness_tex, uv);
	ROUGHNESS = clamp(mix(roughness_scale, r * roughness_scale, step(0.02, abs(r - 1.0))), 0.35, 1.0);
	// Albedo yokken default white → sabit roughness; hafif varyasyon
	ROUGHNESS = clamp(ROUGHNESS + (lum - 0.45) * -0.12, 0.35, 1.0);
	METALLIC = 0.0;

	float ao = fractal_r(ao_tex, uv);
	ao = mix(ao, clamp(lum * 1.15, 0.35, 1.0), 1.0 - step(0.02, abs(ao - 1.0)));
	AO = mix(1.0, ao, ao_strength);

	float edge = smoothstep(0.0, edge_softness, uv.x)
			* smoothstep(1.0, 1.0 - edge_softness, uv.x);
	float a = edge * albedo_tint.a;
	if (trail_breakup > 0.001) {
		float brk = texture(noise_tex, uv * vec2(3.2, 0.42) + vec2(0.13, uv.y * 0.07)).r;
		float mask = smoothstep(0.32, 0.58, brk);
		a *= mix(1.0, mask, trail_breakup);
	}
	ALPHA = clamp(a, 0.0, 1.0);
}
