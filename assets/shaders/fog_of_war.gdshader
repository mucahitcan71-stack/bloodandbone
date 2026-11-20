shader_type canvas_item;
render_mode unshaded, blend_mix;

// 0.0 = unexplored, 0.5 = explored, 1.0 = currently visible.
uniform sampler2D fog_tex : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.06, 0.08, 0.11, 0.93);

void fragment() {
    float state = texture(fog_tex, UV).r;

    // Explored and currently visible terrain stays fully uncovered.
    // Smooth only the transition into unexplored terrain.
    float unexplored = 1.0 - smoothstep(0.02, 0.48, state);

    COLOR = vec4(fog_color.rgb, fog_color.a * unexplored);
}
