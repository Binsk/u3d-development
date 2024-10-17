draw_set_valign(fa_top);
draw_set_halign(fa_left);
// draw_text_color(12, 12, string_ext("FPS: {4}\n{0} x {1}\nM-Factor: {2}\nR-Factor: {3}", [Camera.DISPLAY_WIDTH, Camera.DISPLAY_HEIGHT, material_array[0].scalar.pbr[2], material_array[0].scalar.pbr[1], fps]), c_white, c_white, c_white, c_white, 1.0);
draw_text_color(12, 12, $"FPS: {fps}\nResolution: {Camera.DISPLAY_WIDTH}x{Camera.DISPLAY_HEIGHT}" + 
						$"\nGBuffer vRAM: {string(camera.get_vram_usage() / 1024 / 1024)}MB",
						c_white, c_white, c_white, c_white, 1.0);