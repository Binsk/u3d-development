// Update mouse coordinate:
gmouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

render_width = display_get_gui_width();
render_height = display_get_gui_height();

// Debug display:
if (keyboard_check_pressed(vk_f1)){
	display_debug = modwrap(display_debug + 1, 3);
	show_debug_overlay(display_debug > 0);
	visible = (display_debug != 1)
	with (obj_menu_item)
		visible = (other.display_debug != 1);
	with (obj_tooltip)
		visible = (other.display_debug != 1);
	with (obj_bone_scroll)
		visible = (other.display_debug != 1);
}

// Scroll bone attachment menu:
if (not instance_exists(obj_bone_scroll)){
	if (gmouse.x < render_width - 256){
		if (mouse_wheel_up())
			camera_orbit_distance = max(camera_orbit_distance - 1, 1);
		else if (mouse_wheel_down())
			camera_orbit_distance = min(camera_orbit_distance + 1, 128);
	}
	
	// Handle scrolling model buttons:
	if (gmouse.x >= render_width - 256)
		y_velocity += (mouse_wheel_up() - mouse_wheel_down()) * 512;
		
	y_velocity = clamp(y_velocity, -2048, 2048);
	y_scroll += y_velocity * frame_delta;
	y_velocity = lerp(y_velocity, 0, 0.2 * frame_delta_relative);
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