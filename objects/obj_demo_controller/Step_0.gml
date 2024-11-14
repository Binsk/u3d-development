// Update mouse coordinate:
gmouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

render_width = display_get_gui_width();
render_height = display_get_gui_height();

	// Handle animation look:
if (mouse_check_button(mb_right)){
	camera.calculate_world_ray(gmouse.x, gmouse.y, animation_ray);
	
	with (obj_button_model){
		if (is_undefined(animation_track_lr))
			continue;
		
		var look_vector = vec_sub_vec(other.look_point, vec(0, 0.5, 0));

		var dif_lr = vec_angle_difference(vec(0, 0, 1), vec(look_vector.x, 0, look_vector.z));
		dif_lr /= pi * 0.5;
		dif_lr = 0.5 + (dif_lr * -sign(look_vector.x));
		
		var dif_ud = vec_angle_difference(vec(0, 0, 1), vec(0, look_vector.y, 1));
		dif_ud /= pi * 0.5;
		dif_ud = 0.5 + (dif_ud * sign(look_vector.y)) * 0.5;
		
		other.animation_lr = lerp(other.animation_lr, dif_lr, 0.1 * frame_delta_relative);
		other.animation_ud = lerp(other.animation_ud, dif_ud, 0.1 * frame_delta_relative);
		
		if (animation_tree.get_animation_layer_exists(1)){
			animation_tree.set_animation_layer_lerp(2, other.animation_lr);
			animation_tree.set_animation_layer_lerp(1, other.animation_ud);
		}
		else {
			animation_tree.add_animation_layer_lerp(2, "look-lr", other.animation_lr);
			animation_tree.add_animation_layer_lerp(1, "look-ud", other.animation_ud);
		}
	}
}
else {
	with (obj_button_model){
		if (is_undefined(animation_track_lr))
			continue;
		
		other.animation_lr = lerp(other.animation_lr, 0.5, 0.1 * frame_delta_relative);
		other.animation_ud = lerp(other.animation_ud, 0.5, 0.1 * frame_delta_relative);
		animation_tree.set_animation_layer_lerp(2, other.animation_lr);
		animation_tree.set_animation_layer_lerp(1, other.animation_ud);
	}
}

// Scroll bone attachment menu:
if (not instance_exists(obj_bone_scroll)){
	if (mouse_wheel_up())
		camera_orbit_distance = max(camera_orbit_distance - 1, 1);
	else if (mouse_wheel_down())
		camera_orbit_distance = min(camera_orbit_distance + 1, 128);
}

// Update camera position:
if (camera_is_rotating){
	var pos = vec(cos((current_time - camera_rotation_offset) / 2000), 0.5, -sin((current_time - camera_rotation_offset) / 2000));
	camera.set_position(vec_set_length(pos, camera_orbit_distance));
}
else{
	var pos = camera.get_position();
	pos = vec_set_length(pos, camera_orbit_distance);
	camera.set_position(pos);
}
camera.look_at_up(vec());

// Set window cursor to what was calculated last frame:
window_set_cursor(cursor);

// Recalculate tooltip and cursor icon:
cursor = cr_arrow;
with (obj_tooltip)
	text = "";
	
/// Bone scroll 'overlays' everything, so disable hovering and such when it exists:
if (not instance_exists(obj_bone_scroll)){
	with (obj_menu_item){
		if (not is_hovered)
			continue;
		
		obj_tooltip.text = text_tooltip;
		other.cursor = cr_handpoint;
		break;
	}
}
else{
	with (obj_tooltip)
		text = "Select a bone to attach this model to.";
	
	with (obj_bone_scroll){
		if (is_hovered)
			other.cursor = cr_handpoint;
	}
}

for (var i = 0; i < array_length(model_scale_slider_array); ++i)
	model_scale_slider_array[i].y = slider_ay - i * 64;