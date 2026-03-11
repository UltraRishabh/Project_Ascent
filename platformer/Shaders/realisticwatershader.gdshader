// Godot 4 Stylised River Shader (Final Version)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// -- Colors --
uniform vec4 deep_color : source_color = vec4(0.05, 0.25, 0.4, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.2, 0.5, 0.6, 0.7);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// -- Waves & Flow --
uniform sampler2D wave_noise : hint_normal;
uniform vec2 flow_direction = vec2(0.0, 1.0);
uniform float flow_speed = 0.1;
uniform float wave_strength = 0.08;
uniform float wave_frequency = 3.0;

// -- Foam --
uniform sampler2D foam_noise;
uniform float foam_amount : hint_range(0.0, 2.0) = 1.0;
uniform float foam_sharpness : hint_range(1.0, 20.0) = 8.0;
uniform float foam_fade_distance : hint_range(0.0, 5.0) = 0.5; // <<<< 1. NEW UNIFORM

// -- Refraction & Specular --
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.005;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;

// -- Screen Textures --
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;

varying float v_vertex_y;


void vertex() {
	vec2 flow_offset = flow_direction * TIME * flow_speed;
	vec2 uv1 = UV * wave_frequency + flow_offset;
	vec2 uv2 = UV * wave_frequency * 0.7 + flow_offset * 0.7;
	float noise1 = texture(wave_noise, uv1).r;
	float noise2 = texture(wave_noise, uv2).r;
	float height = (noise1 + noise2) * 0.5;
	VERTEX.y += (height - 0.5) * wave_strength;
	v_vertex_y = VERTEX.y;
}

void fragment() {
	// -- 1. Calculate Flowing Normals --
	vec2 flow_offset = flow_direction * TIME * flow_speed;
	vec3 n1 = texture(wave_noise, (UV * wave_frequency) + flow_offset).rgb;
	vec3 n2 = texture(wave_noise, (UV * wave_frequency * 0.7) + flow_offset * 0.7).rgb;
	vec3 normal = normalize(n1 + n2) * 2.0 - 1.0;
	NORMAL = normal;
	NORMAL_MAP = normal;

	// -- 2. Calculate Water Depth --
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float background_depth = -view_pos.z;
	float surface_depth = FRAGCOORD.z;
	float water_depth = background_depth - surface_depth;
	
	// -- 3. Calculate Depth-based Color --
	float depth_blend = smoothstep(0.0, 1.0, water_depth); // Tweak the '1.0' for color depth
	vec4 water_color = mix(shallow_color, deep_color, depth_blend);

	// -- 4. Calculate Foam --
	// <<<<<<<< 2. REPLACED FOAM LOGIC >>>>>>>>
	// Use the water_depth we just calculated to create the shoreline foam
	float proximity_value = smoothstep(foam_fade_distance, 0.0, water_depth);

	// Distort the foam edge with flowing noise
	vec2 foam_flow_uv = UV * 2.0 - (flow_direction * TIME * flow_speed * 0.5);
	float foam_noise_value = texture(foam_noise, foam_flow_uv).r;
	
	// Combine the proximity foam with noise and sharpen it
	float proximity_foam = pow(proximity_value * foam_noise_value, foam_sharpness);
	
	// Foam on wave crests
	float wave_foam = smoothstep(wave_strength * 0.45, wave_strength * 0.5, v_vertex_y);
	
	// Combine foam types
	float foam_factor = clamp(proximity_foam + wave_foam, 0.0, 1.0) * foam_amount;
	// <<<<<<<< END OF REPLACED SECTION >>>>>>>>
	
	// -- 5. Calculate "Refraction" --
	vec2 distortion = NORMAL_MAP.xy * refraction_strength;
	vec4 refracted_color = texture(screen_texture, SCREEN_UV + distortion);

	// -- 6. Combine everything --
	vec3 final_color = mix(refracted_color.rgb, water_color.rgb, water_color.a);
	final_color = mix(final_color, foam_color.rgb, foam_factor);

	// -- 7. Set Final PBR Output --
	ALBEDO = final_color;
	ALPHA = water_color.a;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}