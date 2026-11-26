shader_type sky;
// Nocne niebo z pikselowymi gwiazdami, księżycem i łuną miasta przy horyzoncie.

void sky() {
	vec3 dir = floor(EYEDIR * 160.0) / 160.0;
	float height = clamp(dir.y, 0.0, 1.0);
	vec3 color = mix(vec3(0.075, 0.045, 0.085), vec3(0.008, 0.012, 0.032), sqrt(height));
	float random = fract(sin(dot(dir, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	if (random > 0.996 && dir.y > 0.08) {
		color += vec3(0.55, 0.57, 0.65) * fract(random * 91.0);
	}
	vec3 moon = normalize(vec3(0.45, 0.5, -0.74));
	float moon_distance = distance(normalize(dir), moon);
	if (moon_distance < 0.045) {
		color = vec3(0.83, 0.85, 0.72) * (random > 0.7 ? 0.82 : 1.0);
	} else {
		color += vec3(0.08, 0.09, 0.12) * max(0.0, 1.0 - moon_distance * 6.0);
	}
	COLOR = color;
}
