shader_type canvas_item;

uniform vec4 oil_colour : source_color;
uniform vec4 background_colour : source_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float emptiness : hint_range(0, 1);

uniform vec2 sprite_scale;
uniform float scale_x = 1.0;

float rand(vec2 coord) {
    return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 coord){
    vec2 i = floor(coord);
    vec2 f = fract(coord);
    
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    
    vec2 cubic = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

void fragment() {
    vec2 uv = UV; // UV coordinates for the current fragment
    vec2 noisecoord1 = uv * sprite_scale * scale_x;
    vec2 noisecoord2 = uv * sprite_scale * scale_x + 4.0;
    
    vec2 motion1 = vec2(TIME * 0.3, TIME * -0.4);
    vec2 motion2 = vec2(TIME * 0.1, TIME * 0.5);
    
    vec2 distort1 = vec2(noise(noisecoord1 + motion1), noise(noisecoord2 + motion1)) - vec2(emptiness*50.0, emptiness *50.0);
    vec2 distort2 = vec2(noise(noisecoord1 + motion2), noise(noisecoord2 + motion2)) - vec2(emptiness*50.0, emptiness *50.0);
    
    vec2 distortsum = (distort1 + distort2) / 80.0;
    
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV + distortsum);
    
    color = mix(color, oil_colour, 0.3);
    color.rgb = mix(vec3(0.5), color.rgb, 1.4);
    
    float near_top = (uv.y + distortsum.y) / (0.1 / sprite_scale.y);
    near_top = clamp(near_top, 0.0, 1.0);
    near_top = 1.0 - near_top;
    
    color = mix(color, vec4(1.0), near_top);
    
    float edge_lower = 0.6;
    float edge_upper = edge_lower + 0.1;
    
    if(near_top > edge_lower){
        color.a = 0.0;
        
        if(near_top < edge_upper){
            color.a = (edge_upper - near_top) / (edge_upper - edge_lower);
        }
    }
    
    COLOR = color;
}
