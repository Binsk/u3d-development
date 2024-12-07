draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var c = (is_hovered ? color_hovered : color_primary);
if (is_disabled)
	c = color_primary_disabled;

draw_rectangle_color(x, y, x + width, y + height, c, c, c, c, false);

c = (is_disabled ? color_bright_disabled : color_bright)
draw_text_color(x + width * 0.5, y + height * 0.5, text, c, c, c, c, draw_get_alpha());