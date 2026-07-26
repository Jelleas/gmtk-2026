shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.66, 0.20, 1.0);
uniform float outline_width : hint_range(0.0, 8.0) = 0.0;
uniform float fill_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	// cup.png has an opaque body, so its liquid cannot be revealed from below.
	// The outline itself is the bottom-up progress indicator until cup-full.png
	// replaces this texture at the end of the recharge.
	float fill_line = mix(0.735, 0.600, fill_amount);
	if (tex_color.a > 0.0) {
		COLOR = tex_color;
	} else {
		vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_width;
		float nearby_alpha =
			texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a +
			texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a +
			texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)).a +
			texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)).a +
			texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)).a +
			texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)).a;
		float pulse = 0.75 + sin(TIME * 3.0) * 0.25;
		bool is_full = fill_amount >= 0.999;
		bool has_fill = fill_amount > 0.001;
		COLOR = nearby_alpha > 0.0 && has_fill && (is_full || UV.y >= fill_line) ? vec4(outline_color.rgb, outline_color.a * pulse) : vec4(0.0);
	}
}
