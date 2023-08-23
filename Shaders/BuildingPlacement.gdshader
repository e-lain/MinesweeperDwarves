shader_type canvas_item;

uniform vec3 override_color: source_color;

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR.rgb = override_color;
	COLOR.a = alpha;
}
