shader_type canvas_item;
render_mode unshaded, blend_mix;

#include "res://assets/shaders/ashen_veil.gdshaderinc"

void fragment() {
    COLOR = ashen_veil(UV);
}
