shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 asphalt_color : source_color = vec3(0.20, 0.20, 0.22);
uniform vec3 shoulder_dirt : source_color = vec3(0.55, 0.47, 0.35);
uniform vec3 yellow_line_color : source_color = vec3(0.85, 0.70, 0.15);
uniform vec3 white_line_color : source_color = vec3(0.85, 0.85, 0.85);

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
    // UV.x vai de 0 a 1 na largura da via, UV.y corre no comprimento
    float u = UV.x;
    float v = UV.y * 10.0;
    
    // Asfalto base com ruído de pedregulhos e asfalto quebrado
    float grain = noise(UV * vec2(20.0, 80.0)) * 0.12;
    vec3 col = asphalt_color + vec3(grain - 0.06);
    
    // Faixa central amarela tracejada
    float center_dist = abs(u - 0.5);
    float is_center_line = step(center_dist, 0.015);
    float is_dash = step(0.4, fract(v * 0.5));
    col = mix(col, yellow_line_color, is_center_line * is_dash);
    
    // Faixas brancas contínuas nas margens
    float left_edge = smoothstep(0.08, 0.10, u) - smoothstep(0.11, 0.13, u);
    float right_edge = smoothstep(0.87, 0.89, u) - smoothstep(0.90, 0.92, u);
    col = mix(col, white_line_color, clamp(left_edge + right_edge, 0.0, 1.0));
    
    // Acúmulo de poeira e areia do deserto nas bordas do asfalto
    float dirt_mask_l = 1.0 - smoothstep(0.0, 0.18, u + (noise(vec2(v, 1.0)) * 0.06));
    float dirt_mask_r = smoothstep(0.82, 1.0, u - (noise(vec2(v, 2.0)) * 0.06));
    col = mix(col, shoulder_dirt, clamp(dirt_mask_l + dirt_mask_r, 0.0, 1.0));
    
    ALBEDO = col;
    ROUGHNESS = mix(0.70, 0.95, dirt_mask_l + dirt_mask_r);
    SPECULAR = 0.25;
}
