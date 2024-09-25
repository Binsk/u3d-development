var gpu_state = gpu_get_state();

// Regenerate camera GBuffers as needed
var camera_keys = struct_get_names(camera_map);
	
// Render camera GBuffers
for (var i = array_length(camera_keys) - 1; i >= 0; --i){
	var camera = camera_map[$ camera_keys[i]];
	
	/// @note	We re-generate here because we will eventually have to build
	///			custom arrays for each camera
	var body_keys = struct_get_names(body_map);
	var body_array = array_create(array_length(body_keys), undefined);
	for (var j = array_length(body_keys) - 1; j >= 0; --j)
		body_array[j] = body_map[$ body_keys[j]];
	
	camera.render_gbuffer(body_array);
}

if (shader_current() >= 0)
	shader_reset();

gpu_set_state(gpu_state);