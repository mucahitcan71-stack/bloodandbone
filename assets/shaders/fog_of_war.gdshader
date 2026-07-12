shader_type canvas_item;
render_mode unshaded, blend_mix;

// R: 1 = acik (gorus/kesif), 0 = sis. Linear filtre = yumusak kenar.
uniform sampler2D fog_tex : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.06, 0.08, 0.11, 0.93);

void fragment() {
	float clear_amt = texture(fog_tex, UV).r;
	float fog_a = fog_color.a * (1.0 - clear_amt);
	COLOR = vec4(fog_color.rgb, fog_a);
}
