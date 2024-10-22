draw_line_width(x, y, x + 256, y, 2);
var c = make_color_rgb(24 + is_hovered * 32, 24 + is_hovered * 32, 48 + is_hovered * 64);
if (is_dragging)
	c = c_yellow;

draw_circle_color(x + lerp(0, 256, drag_value), y, 10, c, c, false);
draw_circle_color(x + lerp(0, 256, drag_value), y, 7, c_black, c_black, false);
draw_circle_color(x + lerp(0, 256, drag_value), y, 3, c, c, false);

draw_set_halign(fa_left);
draw_set_valign(fa_bottom);
draw_text_color(x, y - 16, text, c_white, c_white, c_white, c_white, 1.0);