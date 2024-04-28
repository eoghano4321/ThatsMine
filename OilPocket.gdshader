shader_type canvas_item;

uniform float fullness : hint_range(0.0, 1.0);
uniform float minY;
uniform float maxY;

uniform vec4 empCol :source_color;
uniform vec4 liqCol :source_color;

void fragment() {
    float liquidHeight = mix(maxY, minY, fullness);

    // Determine whether the fragment is in the liquid or empty part
    vec4 finalColor = (VERTEX.y <= liquidHeight) ? empCol : liqCol;

    // Output final color
    COLOR = finalColor;
}
