if (initialize_count > 0)
	return;

if (initialize_count > -15)
	environment_map.set_texture(sprite_get_texture(spr_default_environment_cube, 1));
	
draw_text_color(12, 12, string_ext("{0} x {1}\nM-Factor: {2}\nR-Factor: {3}", [surface_get_width(application_surface), surface_get_height(application_surface), material_array[0].scalar.pbr[2], material_array[0].scalar.pbr[1]]), c_white, c_white, c_white, c_white, 1.0);

if (keyboard_check(ord("2"))){
	draw_primitive_begin_texture(pr_trianglestrip, environment_map.get_texture());
	draw_vertex_texture_color(0, 0, 0, 0, c_white, 1.0);
	draw_vertex_texture_color(768 * 1.5 * 0.5, 0, 1, 0, c_white, 1.0);
	draw_vertex_texture_color(0, 768 * 0.75 * 0.5, 0, 1, c_white, 1.0);
	draw_vertex_texture_color(768 * 1.5 * 0.5, 768 * 0.75 * 0.5, 1, 1, c_white, 1.0);
	draw_primitive_end();
}