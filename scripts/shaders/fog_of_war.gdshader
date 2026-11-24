shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform sampler2D fog_texture : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.03, 0.04, 0.05, 1.0);
uniform vec4 shroud_color : source_color = vec4(0.01, 0.01, 0.02, 1.0);

void fragment() {
	vec4 fog_data = texture(fog_texture, UV);
	float explored = fog_data.r;
	float visible_now = fog_data.g;

	if (explored < 0.05) {
		ALBEDO = shroud_color.rgb;
		ALPHA = 0.98;
	} else {
		// Suavização entre névoa de guerra e visão limpa
		float fog_strength = (1.0 - smoothstep(0.1, 0.9, visible_now)) * 0.65;
		ALBEDO = fog_color.rgb;
		ALPHA = fog_strength;
	}
}
