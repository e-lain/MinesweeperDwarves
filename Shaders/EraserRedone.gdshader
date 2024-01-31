shader_type canvas_item;

uniform float RotationDegrees: hint_range(0, 360) = 45.0;
uniform int sections :hint_range(0,10) = 3;
uniform float progress : hint_range(0, 1.1) = 0.0;
uniform float FadeWidth : hint_range(0, 1) = 0.025;
uniform float EraserCurvature : hint_range(0.5, 20.0) = 2.0;

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	uv -= pivot;
	return vec2(
		cosa * uv.x - sina * uv.y,
		cosa * uv.y + sina * uv.x 
	) + pivot;
}

void fragment() {
	float rotation = radians(RotationDegrees);
	vec2 pivot = vec2(0.5, 0.5);
	vec2 uv = UV;
	uv.y = uv.y + pow((UV.x - 0.5) / EraserCurvature, 2);
	
	// First calculate UV rotation
	vec2 UVrotated = rotateUV(uv, pivot, rotation);
	// Then get the rotations for the bounds TODO: Precalculate these for 4 corners once I pick the rotation I like
	vec2 topLeft = rotateUV(vec2(0, 0), pivot, rotation);
	vec2 topRight = rotateUV(vec2(1, 0), pivot, rotation);
	vec2 bottomLeft = rotateUV(vec2(0, 1), pivot, rotation);
	vec2 bottomRight = rotateUV(vec2(1, 1), pivot, rotation);
	
	// Assume a 1:1 aspect ratio 
	float minBounds = min(min(topLeft.x, bottomLeft.x), min(topRight.x, bottomRight.x));
	float maxBounds = max(max(topLeft.x, bottomLeft.x), max(topRight.x, bottomRight.x));
	
	float scale = (maxBounds - minBounds);
	vec2 scaleOrigin = vec2(0.5, 0.5);
	vec2 UVScaled = ((UVrotated - scaleOrigin) / scale) + scaleOrigin;
	
	float sectionThickness = 1.0f / float(sections);
	
	float UVOffsetY = UVScaled.y - sectionThickness;
	
	float scaledProgress = float(sections) * progress;
	float flooredProgress = floor(scaledProgress);
	
	float currentSectionProgress = scaledProgress - flooredProgress;
	float sectionsCompletedPct = flooredProgress / float(sections);
	
	
	float hiddenSectionsMask = smoothstep(sectionsCompletedPct, sectionsCompletedPct+FadeWidth, UVScaled.y);
	float completedSectionsMask = smoothstep(sectionsCompletedPct, sectionsCompletedPct+FadeWidth, UVOffsetY);
	
	
	float isEven = step(0.5, mod(flooredProgress, 2));
	float xCoord = mix(UVScaled.x, 1.0-UVScaled.x, isEven); 
	
	float uvXNormalized = (1.0 - FadeWidth) * (xCoord + FadeWidth);
	float currentSectionWithFadeWidth = currentSectionProgress + FadeWidth;
	float erasedMask = smoothstep(currentSectionProgress, currentSectionWithFadeWidth, uvXNormalized);
	float xMask = erasedMask * hiddenSectionsMask;
	float mask = max(xMask, completedSectionsMask);
	
	
	
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= mask;
}
