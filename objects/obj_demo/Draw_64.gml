var material_count = 0;
var primitive_count = 0;
var mesh_count = 0;
var model_count = 0;
var triangle_count = 0;
var animation_string = "Animation Tracks:\n";

with (obj_button){
	if (is_undefined(body))
		continue;
	
	material_count += model.get_material_count();
	primitive_count += model.get_primitive_count();
	mesh_count += model.get_mesh_count();
	triangle_count += model.get_triangle_count();
	model_count++;
}

if (not is_undefined(body) and obj_render_controller.has_body(body)){
	material_count += body.model_instance.get_material_count();
	primitive_count += body.model_instance.get_primitive_count();
	mesh_count += body.model_instance.get_mesh_count();
	triangle_count += body.model_instance.get_triangle_count();
	model_count++;
}

draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_text_color(12, 12, $"{gpu_string}\n" + 
						$"\nFPS: {fps}\nResolution: {camera.buffer_width}x{camera.buffer_height}" + 
						$"\nGBuffer vRAM: {string(camera.get_vram_usage() / 1024 / 1024)}MB" + 
						$"\n\nMaterials: {material_count} [{self.material_count} in RAM]\n" +
						$"Models: {model_count} [{self.model_count} in RAM]\n" + 
						$"Meshes: {mesh_count} [{self.mesh_count} in RAM]\n" + 
						$"Primitives: {primitive_count} [{self.primitive_count} in RAM]\nTriangles: {triangle_count}",
						c_white, c_white, c_white, c_white, 1.0);

// Draw animation strings + clickable interaction:
var ax = 256 + 12;
var ay = 12;
draw_text_color(ax, 12, "Animation Tracks:", c_white, c_white, c_white, c_white, 1.0);

with (obj_button){
	if (is_undefined(body))
		continue;
	
	ay += 20;
	
	if (is_undefined(animation_tree)){
		draw_text_color(ax, ay, $"  [{text}] [bones {is_undefined(animation_tree) ? 0 : animation_tree.get_max_bone_count()}] : N/A", c_white, c_white, c_white, c_white, 1.0);
		continue;
	}
	
	var names = animation_tree.get_track_names();
	var str = $"  [{text}] [bones {is_undefined(animation_tree) ? 0 : animation_tree.get_max_bone_count()}] : ";
	draw_text_color(ax, ay, str, c_white, c_white, c_white, c_white, 1.0);
	for (var i = 0; i < array_length(names); ++i){
		var xoffset = string_width(str);
		var c = animation_tree.test_track == names[i] ? c_yellow : c_white;
		var is_hovered = point_in_rectangle(gmouse.x, gmouse.y, ax + xoffset, ay - 2, ax + xoffset + string_width(names[i]), ay + 16);
		if (is_hovered){
			other.cursor = cr_handpoint;
			c = make_color_rgb(24 + is_hovered * 32, 24 + is_hovered * 32, 48 + is_hovered * 64);
			if (mouse_check_button_pressed(mb_left)){
				if (animation_tree.test_track == names[i])
					animation_tree.test_track = "";
				else
					animation_tree.test_track = names[i];
			}
		}
		draw_text_color(ax + xoffset, ay, names[i], c, c, c, c, 1.0);
		str += names[i] + " ";
	}
}