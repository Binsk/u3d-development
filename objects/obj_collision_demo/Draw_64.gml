draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_text_color(12, 12, $"{gpu_string}\n" + 
						$"\nFPS: {fps}\n" +
						$"Collidable Count: {array_length(body_array) + 2}\n" +  // Add 2, one for the camera one for the plane
						$"Scan Depth (fast): {obj_collision_controller.partition_layers[$ "default"].debug_scan_count}\n" +
						$"Scan Count (slow): {obj_collision_controller.get_scan_count()}\n" +
						$"Scan Total: {obj_collision_controller.get_scan_count() + obj_collision_controller.partition_layers[$ "default"].debug_scan_count}",
						c_white, c_white, c_white, c_white, 1.0);