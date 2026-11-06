shader_type canvas_item;
render_mode unshaded, blend_mix;

// R: 0 = unknown, 0.5 = explored, 1 = currently visible.
uniform sampler2D fog_tex : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.06, 0.08, 0.11, 0.93);
uniform float explored_alpha : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	float state = texture(fog_tex, UV).r;
	float fog_a = mix(fog_color.a, explored_alpha, clamp(state * 2.0, 0.0, 1.0));
	fog_a = mix(fog_a, 0.0, clamp(state * 2.0 - 1.0, 0.0, 1.0));
	COLOR = vec4(fog_color.rgb, fog_a);
}