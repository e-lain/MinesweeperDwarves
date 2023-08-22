shader_type canvas_item;

uniform float speed : hint_range(0.0, 10.0, 0.01) = 3.0;

void fragment() {
	
    COLOR = texture(TEXTURE, vec2((VERTEX.y / 1280.0) + UV.x + TIME * speed, UV.y));
}