/// @about
/// The render controller handles executing the rendering pipeline and merging camera
/// buffers together onto the screen.

enum RENDER_STAGE {
	build_gbuffer,
	light_pass,
	post_processing
}

#region PROPERTIES
body_map = {};	// Map of all bodies in the scene; sorted via IDs
camera_map = {};	// Map of all cameras to render
#endregion

#region METHODS
/// @desc	Add a body to the rendering system if it isn't already added. Returns
///			if successful.
function add_body(body){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return false;
	}
	
	// If the body already exists in the system, exit early
	if (not is_undefined(body_map[$ body.get_index()]))
		return false;
	
	body_map[$ body.get_index()] = body;
	body.signaler.add_signal("free", new Callable(id, remove_body, [body])); // Attach signal to auto-remove if the body is freed
	return true;
}

/// @desc	Removes the specified body from the rendering system
function remove_body(body){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return false;
	}
	
	// If the body doesn't exist, don't bother
	if (is_undefined(body_map[$ body.get_index()]))
		return false;
	
	struct_remove(body_map, body.get_index());
	body.signaler.remove_signal("free", new Callable(id, remove_body, [body])); // Remove 'auto-free' signal
	return true;
}

/// @desc	Add a camera to the rendering system if it isn't already added. Returns
///			if successful.
function add_camera(camera){
	if (not is_instanceof(camera, Camera)){
		Exception.throw_conditional("invalid type, expected [Camera]!");
		return false;
	}
	
	// If the body already exists in the system, exit early
	if (not is_undefined(camera_map[$ camera.get_index()]))
		return false;
	
	camera_map[$ camera.get_index()] = camera;
	camera.signaler.add_signal("free", new Callable(id, remove_camera, [camera])); // Attach signal to auto-remove if the body is freed
	return true;
}

/// @desc	Removes the specified camera from the rendering system
function remove_camera(camera){
	if (not is_instanceof(camera, Camera)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return false;
	}
	
	// If the body doesn't exist, don't bother
	if (is_undefined(camera_map[$ camera.get_index()]))
		return false;
	
	struct_remove(camera_map, camera.get_index());
	camera.signaler.remove_signal("free", new Callable(id, remove_camera, [camera])); // Remove 'auto-free' signal
	return true;
}

/// @desc	Build an ordered array of renderable bodies for the specified camera.
function build_render_body_array(camera_id){
	/// @note	Currently, camera does not matter but this will allow for handling
	///			instance culling and other optimizations down the line.
	
	var keys = struct_get_names(body_map);
	var array = array_create(array_length(keys), undefined);
	for (var i = array_length(keys) - 1; i >= 0; --i)
		array[i] = body_map[$ keys[i]];
	
	return array;
}
#endregion

#region INIT
#endregion