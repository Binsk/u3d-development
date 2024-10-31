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

function surface_clear(surface, color, alpha=1.0){
	if (not surface_exists(surface))
		return;
	
	surface_set_target(surface);
	draw_clear_alpha(color, alpha);
	surface_reset_target();
}

/// @desc	Sets a value for the specified uniform name under the currently
///			applied shader. Used in materials, lights, and so-forth to allow
///			dynamically changing out shaders w/o having to worry about updating
///			uniform IDs.
gml_pragma("forceinline");
function uniform_set(name, uniform_fnc=shader_set_uniform_f, argv=[]){
	static UNIFORM_CACHE = {};
	var shader = shader_current();
	if (shader < 0) // Skip if no shader set
		return;
		
	var label = $"__uniform_{name}_{shader}";
	var uniform = UNIFORM_CACHE[$ label];
	
	if (is_undefined(uniform)){ // If we haven't checked this uniform + shader combo, look it up
		uniform = shader_get_uniform(shader, name);
		UNIFORM_CACHE[$ label] = uniform;
	}
	
	if (uniform >= 0){ // Uniform exists in the shader; set it
		var array = array_concat([uniform], is_array(argv) ? argv : [argv]);
		method_call(uniform_fnc, array);
	}
}

/// @stub	Add in a sampler version of uniform_set