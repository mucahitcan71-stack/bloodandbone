shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;
stencil_mode write, compare_always, 1;

uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;

void fragment() {
    // Reverse Z: only mark fragments at or in front of the opaque scene depth.
    float opaque_depth = texture(scene_depth, SCREEN_UV).r;
    // The opaque and stencil passes can round the same interpolated depth differently.
    uint depth_bits = floatBitsToUint(opaque_depth);
    float nearest_depth = uintBitsToFloat(depth_bits - min(depth_bits, 4u));
    if (FRAGCOORD.z < nearest_depth) {
        discard;
    }
    ALPHA = 0.0;
}
