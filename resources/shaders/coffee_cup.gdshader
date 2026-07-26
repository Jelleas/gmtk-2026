shader_type canvas_item;

uniform vec4 coffee_color : source_color = vec4(0.22, 0.10, 0.04, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 0.66, 0.20, 1.0);
uniform float outline_width : hint_range(0.0, 8.0) = 0.0;
uniform float fill_amount : hint_range(0.0, 1.0) = 1.0;
uniform float active_glow : hint_range(0.0, 1.0) = 0.0;
uniform float dim_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (tex_color.a > 0.0) {
		// cup.png is a full-screen texture; these bounds isolate the mug's rim and base.
		float fill_line = mix(0.735, 0.600, fill_amount);
		vec3 color = tex_color.rgb;
		if (UV.y >= fill_line) {
			color = mix(color, coffee_color.rgb, 0.72);
		}
		// A visible liquid surface makes the bottom-up recharge readable on the cup.
		float surface = 1.0 - smoothstep(0.0, 0.004, abs(UV.y - fill_line));
		color = mix(color, coffee_color.rgb * 0.55, surface);
		float luminance = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(color, vec3(luminance), dim_amount);
		color += outline_color.rgb * active_glow * 0.18;
		COLOR = vec4(color, tex_color.a);
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
		COLOR = nearby_alpha > 0.0 ? vec4(outline_color.rgb, outline_color.a * pulse) : vec4(0.0);
	}
}
