draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_text_color(12, 12, $"{gpu_string}\n" + 
						$"\nFPS: {fps}\n" +
						$"Scan Count: {obj_collision_controller.get_scan_count()}",
						c_white, c_white, c_white, c_white, 1.0);