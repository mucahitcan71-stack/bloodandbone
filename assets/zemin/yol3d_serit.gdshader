shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(0.62, 0.50, 0.34, 1.0);
uniform float edge_softness : hint_range(0.05, 0.45) = 0.22;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	float edge = smoothstep(0.0, edge_softness, UV.x)
			* smoothstep(0.0, edge_softness, 1.0 - UV.x);
	ALBEDO = tex * albedo_tint.rgb;
	ALPHA = clamp(edge * albedo_tint.a, 0.0, 1.0);
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
}
