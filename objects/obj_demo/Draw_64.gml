draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_text_color(12, 12, $"FPS: {fps}\nResolution: {Camera.DISPLAY_WIDTH}x{Camera.DISPLAY_HEIGHT}" + 
						$"\nGBuffer vRAM: {string(camera.get_vram_usage() / 1024 / 1024)}MB",
						c_white, c_white, c_white, c_white, 1.0);