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