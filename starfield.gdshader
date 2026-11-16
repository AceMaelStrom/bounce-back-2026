shader_type spatial;
render_mode unshaded;

uniform vec4 background_color : source_color = vec4(0.01, 0.02, 0.08, 1.0);
uniform float aspect_ratio = 1.0;
uniform float density : hint_range(0.0, 3.0, 0.0001) = 1.3;
uniform int layer_parascale : hint_range(0, 5, 1) = 4;
uniform vec2 star_speed = vec2(0.01, 0.035);
uniform vec2 star_wave = vec2(0.25, 0.4);
uniform float star_size : hint_range(0.0, 100.0, 0.01) = 3.0;
uniform float star_rotate_speed : hint_range(-3.0, 3.0) = 0.03;
uniform float twinkle_effect : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float twinkle_speed : hint_range(0.0, 100.0, 0.01) = 2.0;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float one_div_x(float x) {
	return (abs(x) < 0.0001) ? 1.0 : (1.0 / x);
}

float one_div_x2(float x) {
	return one_div_x(x) * one_div_x(x);
}

float get_beta_w(float x, float f, float size) {
	return size * x * PI / f;
}

float get_beta_h(float y, float f, float size) {
	return size * y * PI / f;
}

float get_i(vec2 uv, float f, vec2 size) {
	return one_div_x2(get_beta_w(uv.x, f, size.x)) * one_div_x2(get_beta_h(uv.y, f, size.y));
}

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43759.5453123);
}

vec2 get_star_center(vec2 grid_id, vec2 time_offset, vec2 star_offset, float layer_scale) {
	return (grid_id + star_offset + time_offset) / layer_scale;
}

vec2 rotate_star(vec2 uv, float add_theta) {
	float theta = atan(uv.y, uv.x) + add_theta;
	float radius = length(uv);
	return vec2(radius * cos(theta), radius * sin(theta));
}

void fragment() {
	vec4 color = background_color;
	vec2 st = UV;
	st.x *= aspect_ratio;
	vec2 centered_uv = (st - 0.5) * 2.0;

	for (int layer = 0; layer < layer_parascale; layer++) {
		float layer_scale = exp(float(layer + 1) * density);
		vec2 layer_speed = star_speed * (1.0 + float(layer) * 0.3);
		float layer_size = star_size * (1.0 - float(layer) * 0.2);
		vec2 layer_st = st * layer_scale;
		vec2 time_offset = TIME * layer_speed;
		layer_st -= time_offset;

		vec2 grid_st = fract(layer_st);
		vec2 grid_id = floor(layer_st);
		float rand_seed = random(grid_id);
		vec2 star_pos = vec2(
			0.5 + 0.3 * sin(rand_seed * 6.28 + TIME * star_wave.x),
			0.5 + 0.2 * cos(rand_seed * 12.56 + TIME * star_wave.y)
		);

		float dist = distance(grid_st, star_pos);
		float point_size = layer_size * 0.01 * (0.5 + 0.5 * rand_seed);
		float brightness = 1.0 - float(layer) * 0.3;
		float mask = exp((-dist * dist) / (point_size * point_size));
		vec2 star_uv = centered_uv - (get_star_center(grid_id, time_offset, star_pos, layer_scale) - 0.5) * 2.0;
		star_uv = rotate_star(star_uv, TIME * star_rotate_speed);
		float star = mask * 0.5 * (get_i(star_uv, 0.8 - dist * 42.0, vec2(1.0 / point_size)) + 1.0);
		float twinkle = (1.0 - twinkle_effect) + twinkle_effect * (sin(rand_seed * 100.0 + TIME * twinkle_speed) * cos(rand_seed * 120.0 + TIME * (twinkle_speed + 2.0)));
		star *= twinkle;
		vec3 star_color = vec3(random(grid_id - 3.0), random(grid_id + 7.0), random(grid_id + 5.0));
		color = max(color, color + star * brightness * vec4(star_color, 1.0));
	}

	vec3 surface_color = vec3(0.16, 0.21, 0.29);
	vec2 floor_uv = world_position.xz;
	if (abs(world_normal.y) < 0.5) {
		surface_color = vec3(0.26, 0.33, 0.43);
		floor_uv = vec2(world_position.x + world_position.z, world_position.y);
	} else if (world_normal.y < 0.0) {
		surface_color = vec3(0.11, 0.15, 0.23);
	}
	vec2 grid = abs(fract(floor_uv / 5.0) - 0.5);
	float line = smoothstep(0.485, 0.495, max(grid.x, grid.y));
	ALBEDO = surface_color * 0.8 + min(color.rgb, vec3(1.0)) * 0.6 + line * vec3(0.07, 0.1, 0.14);
}
