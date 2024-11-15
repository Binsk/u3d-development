var c = (is_hovered ? color_hovered : color_primary);
if (is_disabled)
	c = color_primary_disabled;
	
draw_rectangle_color(x, y, x + size, y + size, c, c, c, c, false);
if (is_checked){
	c = is_disabled ? color_bright_disabled : color_highlight;
	draw_rectangle_color(x + 5, y + 5, x + size - 5, y + size - 5, c, c, c, c, false);
}
	
draw_set_valign(fa_middle);
draw_set_halign(fa_left);

c = (is_disabled ? color_bright_disabled : color_bright);
draw_text_color(x + size * 1.5, y + size * 0.5, text, c, c, c, c, 1.0);