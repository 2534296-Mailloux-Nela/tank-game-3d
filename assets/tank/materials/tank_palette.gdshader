shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back,
	diffuse_burley, specular_schlick_ggx;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform int tank_color : hint_enum("Vert", "Bleu", "Rouge", "Orange") = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

varying vec2 uv3;
varying vec2 uv4;


void vertex() {
	uv3 = CUSTOM0.xy;
	uv4 = CUSTOM0.zw;
}


void fragment() {
	vec2 selected_uv = UV;

	if (tank_color == 1) {
		selected_uv = UV2;
	} else if (tank_color == 2) {
		selected_uv = uv3;
	} else if (tank_color == 3) {
		selected_uv = uv4;
	}

	ALBEDO = texture(texture_albedo, selected_uv).rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
}
