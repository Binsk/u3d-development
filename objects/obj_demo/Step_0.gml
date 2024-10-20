global.mouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

camera.set_position(vec(distance * cos(current_time / 2000), distance * 0.5, distance * -sin(current_time / 2000)));
camera.look_at_up(vec());

camera_anaglyph.set_position(vec(distance * cos(current_time / 2000 + degtorad(2)), distance * 0.5, distance * -sin(current_time / 2000 + degtorad(2))));
camera_anaglyph.look_at_up(vec());

var cursor = cr_arrow;
with (obj_button){
	if (is_hovered){
		cursor = cr_handpoint;
		break;
	}
}
with (obj_checkbox){
	if (is_hovered){
		cursor = cr_handpoint;
		break;
	}
}

window_set_cursor(cursor);