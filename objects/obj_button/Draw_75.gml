draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var c = (is_hovered ? color_hovered : color_primary);

draw_rectangle_color(x, y, x + width, y + height, c, c, c, c, false);
draw_text_color(x + width * 0.5, y + height * 0.5, text, c_white, c_white, c_white, c_white, 1.0);