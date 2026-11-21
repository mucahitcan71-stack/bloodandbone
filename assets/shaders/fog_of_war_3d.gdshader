shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;
stencil_mode read, compare_not_equal, 1;

#include "res://assets/shaders/ashen_veil.gdshaderinc"

uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec2 map_min;
uniform vec2 map_size;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    float depth = texture(scene_depth, SCREEN_UV).r;
    vec2 ndc = SCREEN_UV * 2.0 - 1.0;
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, depth, 1.0);
    vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz / view.w, 1.0)).xyz;
    if (depth == 0.0) {
        // When nothing wrote depth, intersect the camera ray with the map plane.
        vec4 near_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0, 1.0);
        vec3 near_world = (INV_VIEW_MATRIX * vec4(near_view.xyz / near_view.w, 1.0)).xyz;
        world = mix(near_world, world, near_world.y / (near_world.y - world.y));
    }
    vec2 uv = (world.xz - map_min) / map_size;
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
        discard;
    }
    vec4 fog = ashen_veil(uv);
    ALBEDO = fog.rgb;
    ALPHA = fog.a;
}
