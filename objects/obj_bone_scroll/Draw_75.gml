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
			var button_id = obj_demo.primary_button;
			button_id.animation_tree.attach_body(child_body, button_id.body, button_id.animation_tree.get_bone_id(bone_name_array[i]));
			obj_render_controller.add_body(child_body);
			obj_demo.update_data_count();
			instance_destroy();
			return;
		}
	}
	
	draw_text_color(display_get_gui_width() - 12, ry, bone_name_array[i], c, c, c, c, 1.0);
}