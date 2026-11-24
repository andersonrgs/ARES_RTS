shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.64, 0.56, 0.42);
uniform vec3 dark_dirt_color : source_color = vec3(0.48, 0.42, 0.32);
uniform vec3 rock_color : source_color = vec3(0.38, 0.35, 0.30);

// Função de hash 2D rápida
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Ruído suave Value Noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractional Brownian Motion (fBm) para detalhes geológicos
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(100.0);
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    // Camadas de variação do solo do deserto
    float macro_noise = fbm(world_pos * 0.05); // Variação em grande escala (dunas)
    float micro_noise = fbm(world_pos * 0.35); // Variação de cascalho/pedregulhos
    float detail_grain = hash(world_pos * 8.0) * 0.08; // Granulação fina de areia
    
    // Mistura de cores baseada nas camadas de relevo
    vec3 col = mix(base_color, dark_dirt_color, smoothstep(0.35, 0.65, macro_noise));
    col = mix(col, rock_color, smoothstep(0.60, 0.85, micro_noise) * 0.4);
    col += (detail_grain - 0.04);
    
    // Geração de relevo (Normal Mapping procedural a partir do gradiente de altura)
    float eps = 0.15;
    float h_c = fbm(world_pos * 0.35);
    float h_r = fbm((world_pos + vec2(eps, 0.0)) * 0.35);
    float h_u = fbm((world_pos + vec2(0.0, eps)) * 0.35);
    vec3 normal_offset = normalize(vec3((h_c - h_r) * 1.5, 1.0, (h_c - h_u) * 1.5));
    
    ALBEDO = col;
    ROUGHNESS = clamp(0.75 + micro_noise * 0.2, 0.65, 0.95);
    SPECULAR = 0.2;
    NORMAL = (VIEW_MATRIX * vec4(normal_offset, 0.0)).xyz;
}
