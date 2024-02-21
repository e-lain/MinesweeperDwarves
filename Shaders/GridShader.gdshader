shader_type canvas_item;

uniform vec2 min_fade_pos;
uniform vec2 max_fade_pos;
uniform float speed : hint_range(0.0, 10.0, 0.01) = 3.0;
uniform float smooth_distance = 32.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
//	float alpha =  smoothstep(min_fade_pos.y, min_fade_pos.y + smooth_distance, world_pos.y) * smoothstep(min_fade_pos.x, min_fade_pos.x + smooth_distance, world_pos.x) * (1.0 - smoothstep(max_fade_pos.y - smooth_distance, max_fade_pos.y, world_pos.y)) * (1.0 - smoothstep(max_fade_pos.x - smooth_distance, max_fade_pos.x, world_pos.x));
	
	COLOR = texture(TEXTURE, vec2((world_pos.y / 1280.0) + UV.x + TIME * speed, UV.y));
//	COLOR.a = COLOR.a * alpha;
}