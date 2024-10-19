draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_text_color(12, 12, $"FPS: {fps}\nResolution: {Camera.DISPLAY_WIDTH}x{Camera.DISPLAY_HEIGHT}" + 
						$"\nGBuffer vRAM: {string(camera.get_vram_usage() / 1024 / 1024)}MB",
						c_white, c_white, c_white, c_white, 1.0);

if (is_undefined(body))
	return;
	
draw_primitive_begin_texture(pr_trianglestrip, body.model_instance.material_data[$ 0].texture.normal.texture.get_texture());
draw_vertex_texture(0, 0, 0, 0);
draw_vertex_texture(512, 0, 1, 0);
draw_vertex_texture(0, 512, 0, 1);
draw_vertex_texture(512, 512, 1, 1);
draw_primitive_end();