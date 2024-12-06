/// @about
/// This object is a base controller class that all controller systems
/// inherit from. It defines expected methods for the controller systems and handles
/// threading / async (once implemented).

#region PROPERTIES
super = new Super(id);
signaler = new Signaler();
body_map = {};
#endregion

#region METHODS

/// @desc	Adds a body to the controller and returns if the body was added.
///			Bodies are automatically detached when freed.
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

/// @desc	Explicitly removes a body from the controller.
function remove_body(body){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return false;
	}
	
	if (not U3DObject.get_is_valid_object(body))	// In case a cleanup wipes things before us
		return false;
	
	// If the body doesn't exist, don't bother
	if (is_undefined(body_map[$ body.get_index()]))
		return false;
	
	struct_remove(body_map, body.get_index());
	body.signaler.remove_signal("free", new Callable(id, remove_body, [body])); // Remove 'auto-free' signal
	return true;
}

/// @desc	Returns if the body has already been added to this controller.
function has_body(body){
	return not is_undefined(body_map[$ body.get_index()]);
}

/// @desc	Returns an array of all the connected bodies in no particular order.
function get_body_array(){
	return struct_get_values(body_map);
}

/// @desc	Processes the main event for this controller.
function process(){};
#endregion