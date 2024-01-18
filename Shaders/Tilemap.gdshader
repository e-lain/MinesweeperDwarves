shader_type canvas_item;

uniform vec4 background_color_tint : source_color;
uniform vec2 background_scale;
uniform vec2 background_offset;
uniform sampler2D image : source_color, repeat_enable;
uniform mat4 global_transform;

varying vec2 world_pos;

void vertex()
{
	world_pos = (global_transform * vec4(VERTEX, 0.0, 1.0)).xy;	
}


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 size = vec2(textureSize(image, 0));
	vec4 background_color = texture(image, background_offset + (mod(world_pos, size) / float(size.x) * background_scale));
	COLOR.rgb = mix(background_color.rgb, color.rgb, color.a);
	COLOR.a = 1.0;
	COLOR *= background_color_tint;
}
