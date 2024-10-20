draw_set_alpha(0.8);
draw_rectangle_color(11, 1080 - 37, 256 * 3 - 96, 1080 - 11, c_gray, c_gray, c_gray, c_gray, true);
draw_rectangle_color(11, 1080 - 37 - 36, 256 * 3 - 96, 1080 - 11 - 36, c_gray, c_gray, c_gray, c_gray, true);
draw_set_alpha(1.0);

if (keyboard_check_pressed(ord("1"))){
	show_message(debug_get_reference_counts());
}