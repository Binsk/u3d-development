if (initialize_count > 0)
	return;

if (initialize_count > -15)
	environment_map.set_texture(sprite_get_texture(spr_default_environment_cube, 1));
	
// draw_text_color(12, 12, string_ext("FPS: {4}\n{0} x {1}\nM-Factor: {2}\nR-Factor: {3}", [Camera.DISPLAY_WIDTH, Camera.DISPLAY_HEIGHT, material_array[0].scalar.pbr[2], material_array[0].scalar.pbr[1], fps]), c_white, c_white, c_white, c_white, 1.0);
draw_text_color(12, 12, $"FPS: {fps}\nResolution: {Camera.DISPLAY_WIDTH}x{Camera.DISPLAY_HEIGHT}" + 
						$"\nM-Factor: {material_array[0].scalar.pbr[2]} [Shift + Le/Ri]\nR-Factor: {material_array[0].scalar.pbr[1]} [Shift + Up/Do]" +
						$"\nSSAO x8: {light.casts_shadows} [1]",
						c_white, c_white, c_white, c_white, 1.0);
if (keyboard_check(ord("2"))){
	draw_primitive_begin_texture(pr_trianglestrip, environment_map.get_texture());
	draw_vertex_texture_color(0, 0, 0, 0, c_white, 1.0);
	draw_vertex_texture_color(768 * 1.5 * 0.5, 0, 1, 0, c_white, 1.0);
	draw_vertex_texture_color(0, 768 * 0.75 * 0.5, 0, 1, c_white, 1.0);
	draw_vertex_texture_color(768 * 1.5 * 0.5, 768 * 0.75 * 0.5, 1, 1, c_white, 1.0);
	draw_primitive_end();
}