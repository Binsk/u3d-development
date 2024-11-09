global.mouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

if (not instance_exists(obj_bone_scroll)){
	if (mouse_wheel_up())
		distance = max(distance - 1, 1);
	else if (mouse_wheel_down())
		distance = min(distance + 1, 128);
}

if (rotate_camera)
	camera.set_position(vec(distance * cos((current_time - rotation_offset) / 2000), distance * 0.5, distance * -sin((current_time - rotation_offset) / 2000)));
	
camera.look_at_up(vec());

window_set_cursor(cursor);

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