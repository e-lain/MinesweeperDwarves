shader_type canvas_item;

uniform float RotationDegrees: hint_range(0, 360) = 45.0;
uniform int sections :hint_range(0,10) = 3;
uniform float progress : hint_range(0, 1.1) = 0.0;
uniform float FadeWidth : hint_range(0, 1) = 0.025;
uniform float EraserCurvature : hint_range(0.5, 20.0) = 2.0;

uniform vec2 frame_coords = vec2(0,0);
uniform vec2 frame_counts = vec2(1, 1);

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	uv -= pivot;
	return vec2(
		cosa * uv.x - sina * uv.y,
		cosa * uv.y + sina * uv.x 
	) + pivot;
}

vec2 getUVsInFrame(vec2 uv, vec2 pixelSize) {
	vec2 sheet_size = 1.0 / pixelSize;
	vec2 frame_size = sheet_size / frame_counts;
	vec2 current_point = sheet_size * uv;
	vec2 max_point = (frame_size * vec2(frame_coords.x, frame_coords.y)) + frame_size;
	vec2 new_uv = 1.0 - (max_point - current_point) / frame_size;
	return new_uv;

	uv.x = (uv.x / float(frame_counts.x)) + (frame_coords.x / float(frame_counts.x));
	uv.y = (uv.y / float(frame_counts.y)) + (frame_coords.y / float(frame_counts.y));
	return uv;
}


void fragment() {
	float rotation = radians(RotationDegrees);
	vec2 pivot = vec2(0.5, 0.5);
	vec2 uv = getUVsInFrame(UV, TEXTURE_PIXEL_SIZE);
//	COLOR = texture(TEXTURE, uv);
	
	uv.y = uv.y + pow((uv.x - pivot.x) / EraserCurvature, 2);
	
	vec2 bottomRightFrameUV = vec2(1, 1);
	
	// First calculate UV rotation
	vec2 UVrotated = rotateUV(uv, pivot, rotation);
	// Then get the rotations for the bounds TODO: Precalculate these for 4 corners once I pick the rotation I like
	vec2 topLeft = rotateUV(vec2(0, 0), pivot, rotation);
	vec2 topRight = rotateUV(vec2(1, 0), pivot, rotation);
	vec2 bottomLeft = rotateUV(vec2(0, 1), pivot, rotation);
	vec2 bottomRight = rotateUV(bottomRightFrameUV, pivot, rotation);
	
	// Assume a 1:1 aspect ratio 
	float minBounds = min(min(topLeft.x, bottomLeft.x), min(topRight.x, bottomRight.x));
	float maxBounds = max(max(topLeft.x, bottomLeft.x), max(topRight.x, bottomRight.x));
	
	float scale = (maxBounds - minBounds);
	vec2 UVScaled = ((UVrotated - pivot) / scale) + pivot;
	
	float sectionThickness = 1.0f / float(sections);
	
	float UVOffsetY = UVScaled.y - sectionThickness;
	
	float scaledProgress = float(sections) * progress;
	float flooredProgress = floor(scaledProgress);
	
	float currentSectionProgress = scaledProgress - flooredProgress;
	float sectionsCompletedPct = flooredProgress / float(sections);
	
	
	float hiddenSectionsMask = smoothstep(sectionsCompletedPct, sectionsCompletedPct+FadeWidth, UVScaled.y);
	float completedSectionsMask = smoothstep(sectionsCompletedPct, sectionsCompletedPct+FadeWidth, UVOffsetY);
	
	
	
	float isEven = step(0.5, mod(flooredProgress, 2));
	float xCoord = mix(UVScaled.x, bottomRightFrameUV.x-UVScaled.x, isEven); 
	
	
	
	float uvXNormalized = (bottomRightFrameUV.x - FadeWidth) * (xCoord + FadeWidth);
	float currentSectionWithFadeWidth = currentSectionProgress + FadeWidth;
	float erasedMask = smoothstep(currentSectionProgress, currentSectionWithFadeWidth, uvXNormalized);
	float xMask = erasedMask * hiddenSectionsMask;
	float mask = max(xMask, completedSectionsMask);
	
	COLOR.a *= mask;
}
