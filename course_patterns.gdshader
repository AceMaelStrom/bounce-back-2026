shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool tube = false;
varying vec3 position_world;

void vertex() {
	position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (tube) {
		float ring = pow(0.5 + 0.5 * cos(position_world.z * 2.0 + TIME * 0.7), 18.0);
		float stripe = pow(0.5 + 0.5 * sin((position_world.x + position_world.y) * 2.0), 12.0);
		ALBEDO = vec3(0.12, 0.23, 0.28) + ring * vec3(0.06, 0.3, 0.35) + stripe * 0.05;
	} else {
		float tile = mod(floor(position_world.x / 4.0) + floor(position_world.z / 4.0) + floor(position_world.y / 4.0), 2.0);
		float pulse = pow(0.5 + 0.5 * sin(position_world.z * 0.4 + TIME), 12.0);
		ALBEDO = mix(vec3(0.21, 0.17, 0.3), vec3(0.32, 0.27, 0.4), tile) + pulse * vec3(0.12, 0.05, 0.16);
	}
}
