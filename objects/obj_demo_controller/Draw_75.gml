draw_set_alpha(0.8);
draw_rectangle_color(11, display_get_gui_height() - 37, 256 * 3 - 96, display_get_gui_height() - 11, c_gray, c_gray, c_gray, c_gray, true);
draw_rectangle_color(11, display_get_gui_height() - 37 - 36, 256 * 3 - 96, display_get_gui_height() - 11 - 36, c_gray, c_gray, c_gray, c_gray, true);
draw_set_alpha(1.0);

if (instance_exists(obj_bone_scroll)){
	draw_set_alpha(0.6);
	draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(), c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1.0)
}