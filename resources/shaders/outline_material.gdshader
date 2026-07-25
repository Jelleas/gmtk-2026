shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 16.0) = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (tex_color.a > 0.0) {
		COLOR = tex_color;
	} else {
		vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
		float a =
			texture(TEXTURE, UV + vec2( 0.0, -ps.y)).a +
			texture(TEXTURE, UV + vec2( 0.0,  ps.y)).a +
			texture(TEXTURE, UV + vec2(-ps.x,  0.0)).a +
			texture(TEXTURE, UV + vec2( ps.x,  0.0)).a +
			texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a +
			texture(TEXTURE, UV + vec2( ps.x, -ps.y)).a +
			texture(TEXTURE, UV + vec2(-ps.x,  ps.y)).a +
			texture(TEXTURE, UV + vec2( ps.x,  ps.y)).a;

		COLOR = a > 0.0 ? outline_color : vec4(0.0);
	}
}