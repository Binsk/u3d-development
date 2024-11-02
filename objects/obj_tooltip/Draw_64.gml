if (text == "")
	return;
	
var c = make_color_rgb(24 + 32, 24 + 32, 48 + 64);
var text_h = string_height_ext(text, -1, 386);
draw_rectangle_color(12, 12, 24 + 386, max(text_h + 24, 48), c, c, c, c, false);
draw_rectangle_color(12, 12, 24 + 386, max(text_h + 24, 48), c_white, c_white, c_white, c_white, true);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text_ext(24, 24, text, -1, 386);