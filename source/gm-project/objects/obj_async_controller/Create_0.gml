/// @about
///	This controller handles fetching async events thrown by the U3D system. This will generally
/// be texture loads, buffer saves, and similar such features.
image_track = {};

/// @desc	Adds a loading sprite to be monitored and an event executed when it
///			is completed.
/// @param	{sprite}	index
/// @param	{Callable}	callable
function add_sprite_track(index, callable){
	if (not is_undefined(image_track[$ index]))
		throw Exception("failed to track image load, index already exists!");
	
	if (not sprite_exists(index)){ // Should exist, even if unloaded
		Exception.throw_conditional("failed to track image load, sprite index is invalid");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	// Note: Must convert to real to get rid of the "ref" portion of the label
	image_track[$ real(index)] = callable;
}