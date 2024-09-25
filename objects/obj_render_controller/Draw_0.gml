var camera_keys = struct_get_names(camera_map);
for (var i = array_length(camera_keys) - 1; i >= 0; --i){
	var camera = camera_map[$ camera_keys[i]];
	draw_surface(camera.gbuffer.surfaces[$ CAMERA_GBUFFER.albedo], 0, 0);
}