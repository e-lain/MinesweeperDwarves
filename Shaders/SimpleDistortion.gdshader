shader_type canvas_item;

uniform float strength = 0.005;
uniform float speed : hint_range(0, 60) = 4;
uniform sampler2D flowmap : repeat_enable, hint_normal;

varying vec2 local_vert;

void vertex() {
	local_vert = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	float t = speed * TIME;
	vec2 uv = (local_vert * .01) + UV + t;
	vec2 flowVal = texture(flowmap, uv).xy * strength;
	uv = UV + flowVal;

	COLOR = texture(TEXTURE, uv);
	COLOR.a *= 0.8;
}
