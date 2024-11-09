draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var c = make_color_rgb(24 + is_hovered * 32, 24 + is_hovered * 32, 48 + is_hovered * 64);

draw_rectangle_color(x, y, x + width, y + height, c, c, c, c, false);
draw_text_color(x + width * 0.5, y + height * 0.5, text, c_white, c_white, c_white, c_white, 1.0);

if (not is_undefined(body)){
	c = (obj_demo_controller.primary_button == id ? c_yellow : c_lime);
	draw_rectangle_color(x, y, x + width, y + height, c, c, c, c, true);
}