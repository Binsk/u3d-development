/// @stub	Implement proper bone update culling for animation tracks
body_map = {};		// Map of all bodies in the scene

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