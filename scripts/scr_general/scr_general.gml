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

/// @desc	uniform_set is meant to act as a 'local' function and will access
///			the calling class/object's variables locally. It will attempt to
///			look up the uniform for the current shader and set only if it exists.
gml_pragma("forceinline");
function uniform_set(name, uniform_fnc=shader_set_uniform_f, argv=[]){
	var shader = shader_current();
	var label = $"__uniform_{name}_{shader}";
	var uniform = self[$ label];
	
	if (is_undefined(uniform)){
		uniform = shader_get_uniform(shader, name);
		self[$ label] = uniform;
	}
	
	if (uniform >= 0){
		var array = array_concat([uniform], is_array(argv) ? argv : [argv]);
		method_call(uniform_fnc, array);
	}
}

/// @stub	Add in a sampler version of uniform_set