shader_type canvas_item;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	COLOR.a = COLOR.a * min(min(smoothstep(0, 0.1, UV.x), smoothstep(0, 0.1, 1.0 - UV.x)), min(smoothstep(0, 0.1, UV.y), smoothstep(0, 0.1, 1.0 - UV.y) )); 
}
