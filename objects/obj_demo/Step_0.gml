global.mouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

camera.set_position(vec(distance * cos(current_time / 2000), distance * 0.5, distance * -sin(current_time / 2000)));
camera.look_at_up(vec());

window_set_cursor(cursor);

cursor = cr_arrow;
with (obj_button){
	if (is_hovered){
		other.cursor = cr_handpoint;
		break;
	}
}
with (obj_checkbox){
	if (is_hovered){
		other.cursor = cr_handpoint;
		break;
	}
}
with (obj_slider){
	if (is_hovered or is_dragging){
		other.cursor = cr_handpoint;
		break;
	}
}