if (initialize_count > 0)
	return;

environment_map.set_texture(sprite_get_texture(spr_default_environment_cube, 1));
// environment_map.build();
	
draw_text_color(12, 12, string_ext("{0} x {1}\nM-Factor: {2}\nR-Factor: {3}", [surface_get_width(application_surface), surface_get_height(application_surface), material_array[0].scalar.pbr[2], material_array[0].scalar.pbr[1]]), c_white, c_white, c_white, c_white, 1.0);