var c = is_disabled ? color_bright_disabled : color_bright;
draw_line_width_color(x, y, x + 256, y, 2, c, c);
// c = make_color_rgb(24 + is_hovered * 32, 24 + is_hovered * 32, 48 + is_hovered * 64);
c = (is_hovered ? color_hovered : color_primary)
if (is_dragging)
	c = color_highlight;
	
if (is_disabled)
	c = color_primary_disabled;

draw_circle_color(x + lerp(0, 256, drag_value), y, 10, c, c, false);
draw_circle_color(x + lerp(0, 256, drag_value), y, 7, c_black, c_black, false);
draw_circle_color(x + lerp(0, 256, drag_value), y, 3, c, c, false);

draw_set_halign(fa_left);
draw_set_valign(fa_bottom);
c = (is_disabled ? color_bright_disabled : color_bright);
draw_text_color(x, y - 16, text, c, c, c, c, 1.0);