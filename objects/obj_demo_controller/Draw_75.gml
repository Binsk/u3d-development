draw_set_alpha(0.8);
draw_rectangle_color(11, display_get_gui_height() - 37, 256 * 3 - 96, display_get_gui_height() - 11, c_gray, c_gray, c_gray, c_gray, true);
draw_rectangle_color(11, display_get_gui_height() - 37 - 36, 256 * 3 - 96, display_get_gui_height() - 11 - 36, c_gray, c_gray, c_gray, c_gray, true);
draw_set_alpha(1.0);

if (instance_exists(obj_bone_scroll)){
	draw_set_alpha(0.6);
	draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(), c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1.0)
}

if (array_length(error_array) > 0){
	var cx = display_get_gui_width() * 0.5 - 398 * 0.5;
	var cy = display_get_gui_height() * 0.5;
	var text = (array_length(error_array) > 1 ? "Errors:\n  " : "Error:\n  ");
	text += string_join_ext("\n  ", error_array);
	
	var c = make_color_rgb(24 + 32, 24 + 32, 48 + 64);
	var text_h = string_height_ext(text, -1, 386);
	cy -= text_h * 0.5 - 12;
	
	var a = 1.0;
	if (current_time - error_time > 2000)
		a = max(0, 1.0 - ((current_time - 2000) - error_time) * 0.001);
		
	draw_set_alpha(a);
	
	draw_rectangle_color(cx, cy, cx + 24 + 386, cy + max(text_h + 24, 48), c, c, c, c, false);
	draw_rectangle_color(cx, cy, cx + 24 + 386, cy + max(text_h + 24, 48), c_white, c_white, c_white, c_white, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_ext(cx + 6 + 386 * 0.5, cy + max(text_h + 24, 48) * 0.5, text, -1, 386);
	
	if (a <= 0)
		error_array = [];
	
	draw_set_alpha(1.0);
}