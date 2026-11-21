shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D fog_tex : filter_linear, repeat_disable;
uniform sampler2D fog_noise_a : filter_linear, repeat_enable;
uniform sampler2D fog_noise_b : filter_linear, repeat_enable;
uniform vec4 fog_color : source_color = vec4(0.06, 0.08, 0.11, 1.0);
uniform float mist_speed : hint_range(0.0, 0.1) = 0.012;
uniform float mist_strength : hint_range(0.0, 1.0) = 0.65;
uniform float edge_detail : hint_range(0.0, 1.0) = 0.85;

void fragment() {
    float state = texture(fog_tex, UV).r;

    vec2 static_uv = UV * vec2(5.5, 4.0);
    float edge_noise = texture(fog_noise_a, static_uv).r;
    float edge_secondary = texture(fog_noise_b, UV * vec2(11.0, 8.0)).r;

    vec2 drift_a = vec2(TIME * mist_speed, TIME * mist_speed * 0.35);
    vec2 drift_b = vec2(-TIME * mist_speed * 0.25, TIME * mist_speed * 0.55);

    float cloud_a = texture(fog_noise_a, static_uv + drift_a).r;
    float cloud_b = texture(fog_noise_b, UV * vec2(19.0, 17.0) + drift_b).r;
    float clouds = mix(cloud_a, cloud_b, 0.35);

    // Only soften the already interpolated exploration boundary.
    // Fully unknown pixels remain opaque; explored pixels remain clear.
    float edge_zone = smoothstep(0.03, 0.13, state)
                    * (1.0 - smoothstep(0.37, 0.49, state));
    float adjusted_state = state + ((edge_noise - 0.5) * 0.60 + (edge_secondary - 0.5) * 0.25) * edge_detail * edge_zone;
    float fog_alpha = 1.0 - smoothstep(0.09, 0.41, adjusted_state);

    if (state <= 0.02) {
        fog_alpha = 1.0;
    } else if (state >= 0.5) {
        fog_alpha = 0.0;
    }

    // Texture affects only color, never the hidden map's opacity.
    float variation = (clouds - 0.5) * mist_strength * 0.28;
    vec3 tint = clamp(fog_color.rgb + vec3(variation), vec3(0.015), vec3(0.24));

    COLOR = vec4(tint, fog_alpha);
}
