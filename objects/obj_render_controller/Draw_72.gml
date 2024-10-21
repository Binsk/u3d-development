// Build any cube-map textures
	/// @note This WAS handled automatically upon render, but we started having
	///		  shader conflicts so this separate update pass was added.
var cube_keys = struct_get_names(TextureCube.BUILD_MAP);
for (var i = array_length(cube_keys) - 1; i >= 0; --i){
	var cube_map = TextureCube.BUILD_MAP[$ cube_keys[i]];
	cube_map.build();
}

var gpu_state = gpu_get_state();

// Regenerate camera GBuffers as needed
var camera_keys = struct_get_names(camera_map);
	
// Render camera scenes
for (var i = array_length(camera_keys) - 1; i >= 0; --i){
	var camera = camera_map[$ camera_keys[i]];
	
	/// @note	We re-generate here because we will eventually have to build
	///			custom arrays for each camera
	var body_keys = struct_get_names(body_map);
	var body_array = array_create(array_length(body_keys), undefined);
	for (var j = array_length(body_keys) - 1; j >= 0; --j)
		body_array[j] = body_map[$ body_keys[j]];
		
	var light_keys = struct_get_names(light_map);
	var light_array = array_create(array_length(light_keys), undefined);
	for (var j = array_length(light_keys) - 1; j >= 0; --j)
		light_array[j] = light_map[$ light_keys[j]];
	
	camera.update_render_size();
	camera.render(body_array, light_array);
}

if (shader_current() >= 0)
	shader_reset();

gpu_set_state(gpu_state);