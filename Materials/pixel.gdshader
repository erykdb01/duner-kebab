shader_type canvas_item;
// Pikselizacja obrazu 3D z delikatnym ditheringiem i winietą (HUD zostaje ostry).

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float pixel_size = 3.0;
uniform float levels = 32.0;

float bayer2(vec2 at) {
	at = floor(at);
	return fract(at.x / 2.0 + at.y * at.y * 0.75);
}

float bayer4(vec2 at) {
	return bayer2(0.5 * at) * 0.25 + bayer2(at);
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 cell = floor(SCREEN_UV * resolution / pixel_size);
	vec2 uv = (cell + 0.5) * pixel_size / resolution;
	vec3 color = textureLod(screen, uv, 0.0).rgb;
	color = floor(color * levels + bayer4(cell)) / levels;
	float edge = distance(SCREEN_UV, vec2(0.5));
	color *= 1.0 - smoothstep(0.45, 0.8, edge) * 0.35;
	COLOR = vec4(color, 1.0);
}
