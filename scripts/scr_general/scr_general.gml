/// @desc	Print an arbitrary number of strings as a message with a special prefix and
///			callstack. 
function print_traced(prefix="WARNING"){
	var message = "";
	for (var i = 1; i < argument_count; ++i)
		message += string(argument[i]);
	
	var trace = debug_get_callstack(4);
	array_pop(trace); // Remove the trailing '0' from the array
	message = string_upper(prefix) + " ::: [" + array_glue(", ", trace) + "] " + message;
	show_debug_message(message);
}

/// @desc	Returns if the system is using DirectX for rendering. DirectX handles
///			rendering a bit different than OpenGL so we need to change some calculations
///			in these cases.
gml_pragma("forceinline");
function get_is_directx_pipeline(){
	return (os_type == os_windows or os_type == os_xboxone or os_type == os_xboxseriesxs);
}

/// @desc	Clears the specified surface with a color and alpha, just as you would with
/// 		a draw_clear() call.
function surface_clear(surface, color, alpha=1.0){
	if (not surface_exists(surface))
		return;
	
	surface_set_target(surface);
	draw_clear_alpha(color, alpha);
	surface_reset_target();
}

function surface_clear_depth(surface, depth=1.0){
	if (not surface_exists(surface))
		return;
	
	surface_set_target(surface);
	draw_clear_depth(depth);
	surface_reset_target();
}

/// @desc	Sets a value for the specified uniform name under the currently
///			applied shader. Used in materials, lights, and so-forth to allow
///			dynamically changing out shaders w/o having to worry about updating
///			uniform IDs.
// gml_pragma("forceinline");
function uniform_set(name, uniform_fnc=shader_set_uniform_f, argv=[]){
	static UNIFORM_CACHE = {};
	var shader = shader_current();
	if (shader < 0) // Skip if no shader set
		return false;
	
	var data = (UNIFORM_CACHE[$ name] ?? {}); // Note: nested structs as it's marginally cheaper to look up than string concat. Somehow.
	var uniform = data[$ shader];
	
	if (is_undefined(uniform)){ // If we haven't checked this uniform + shader combo, look it up
		uniform = shader_get_uniform(shader, name);
		data[$ shader] = uniform;
		UNIFORM_CACHE[$ name] = data;
	}
	
	if (uniform >= 0){ // Uniform exists in the shader; set it
		var array = array_concat([uniform], is_array(argv) ? argv : [argv]);
		method_call(uniform_fnc, array);
		return true;
	}
	
	return false;
}

/// @desc	Sets a value for the specified uniform sampler name under the current
///			shader.
/// @param	{string}	name
/// @param	{texture}	texture
// gml_pragma("forceinline");
function sampler_set(name, texture){
	static UNIFORM_CACHE = {};
	var shader = shader_current();
	if (shader < 0) // Skip if no shader set
		return false;
		
	var data = (UNIFORM_CACHE[$ name] ?? {});
	var uniform = data[$ shader];
	
	if (is_undefined(uniform)){ // If we haven't checked this uniform + shader combo, look it up
		uniform = shader_get_sampler_index(shader, name);
		data[$ shader] = uniform;
		UNIFORM_CACHE[$ name] = data;
	}
	
	if (uniform >= 0){ // Uniform exists in the shader; set it
		texture_set_stage(uniform, texture);
		return true;
	}
	
	return false;
}
/// @desc	Returns the number of reference objects with the specified type
///			currently being watched by the system. This is slow and intended
/// 		only for debugging use to catch potentially missed references.
function get_ref_instance_count(type=U3DObject){
	var keys = struct_get_names(U3D.MEMORY);
	var count = 0;
	for (var i = array_length(keys) - 1; i >= 0; --i){
		if (is_instanceof(U3DObject.get_ref_data(keys[i]), type))
			count++;
	}
	
	return count;
}

/// @desc	Similar to struct_get_names(), only it just grabs the values
/// 		instead of the keys.
function struct_get_values(struct){
	if (not is_struct(struct))
		return [];
	
	var keys = struct_get_names(struct);
	var array = array_create(array_length(keys), undefined);
	for (var i = array_length(keys) - 1; i >= 0; --i)
		array[i] = struct[$ keys[i]];
	
	return array;
}