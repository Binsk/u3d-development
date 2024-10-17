var c = make_color_rgb(24 + is_hovered * 32, 24 + is_hovered * 32, 48 + is_hovered * 64);
draw_rectangle_color(x, y, x + size, y + size, c, c, c, c, false);
if (is_checked){
	c = c_yellow;
	draw_rectangle_color(x + 5, y + 5, x + size - 5, y + size - 5, c, c, c, c, false);
}
	
draw_set_valign(fa_middle);
draw_set_halign(fa_left);

c = c_white;
draw_text_color(x + size * 1.5, y + size * 0.5, text, c, c, c, c, 1.0);