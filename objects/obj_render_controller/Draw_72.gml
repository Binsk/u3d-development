/// Regenerate camera GBuffers as needed
var keys = struct_get_names(camera_map);
for (var i = array_length(keys) - 1; i >= 0; --i)
	camera_map[keys[i]].generate_gbuffer();	// Only re-generates as needed