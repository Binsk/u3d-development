y_scroll += y_velocity * frame_delta;
y_velocity = lerp(y_velocity, 0, 0.2 * frame_delta_relative);

draw_set_halign(fa_right);
draw_set_valign(fa_top);
is_hovered = false;

var loop = array_length(bone_name_array);
for (var i = 0; i < loop; ++i){
	var c = c_white;
	var ry = 12 + y_scroll + i * 24;
	if (gmouse.y > ry and gmouse.y < ry + 24){
		c = c_yellow;
		is_hovered = true;
		
		if (mouse_check_button_pressed(mb_left)){
			var button_id = obj_render_demo.primary_button;
				// Perform the body attachment
				/// @note	Attachments only update the model matrix, not the individual position, scale, or rotation values!
				///			This means the body will render in the right spot but collisions will NOT!
				///			If collisions are needed you can extract rotation + translation + scale from a matrix manually and
				///			attach a signal to do so upon updates (check the matrix / quat functions)
			button_id.animation_tree.attach_body(child_body, button_id.body, button_id.animation_tree.get_bone_id(bone_name_array[i]));
			
			// Calculate the scale relative to the primary body for editor rendering reasons:
			var child_min_vec = child_body.model_instance.get_data(["import", "aabb_min"], vec());
			var child_max_vec = child_body.model_instance.get_data(["import", "aabb_max"], vec());
			var child_max_comp = vec_max_component(vec_sub_vec(child_max_vec, child_min_vec));
			
			var parent_min_vec = button_id.body.model_instance.get_data(["import", "aabb_min"], vec());
			var parent_max_vec = button_id.body.model_instance.get_data(["import", "aabb_max"], vec());
			var parent_max_comp = vec_max_component(vec_sub_vec(parent_max_vec, parent_min_vec));
			
			var sc = parent_max_comp / child_max_comp * 0.125;
			child_body.set_scale(vec(sc, sc, sc));
			slider_id.min_value = child_body.scale.x * 0.25;
			slider_id.max_value = child_body.scale.x * 5.0;
			slider_id.drag_value = (child_body.scale.x - slider_id.min_value) / (slider_id.max_value - slider_id.min_value);
			slider_id.signaler.signal("drag", [slider_id.drag_value]);
			
			// Since we are now attached, go ahead and add into the rendering system:
			obj_render_controller.add_body(child_body);
			obj_render_demo.update_data_count();	// Update debug data monitoring display
			instance_destroy();
			io_clear();
			return;
		}
	}
	
	draw_text_color(display_get_gui_width() - 12, ry, bone_name_array[i], c, c, c, c, 1.0);
}