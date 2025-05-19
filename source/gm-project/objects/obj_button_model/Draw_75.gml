draw_set_alpha(1.0 - clamp((y - obj_render_demo.render_height * 0.5) * 0.01, 0, 1));
	
event_inherited();
if (not is_undefined(body)){
	var c = (obj_render_demo.primary_button == id ? color_highlight : c_lime);
	draw_rectangle_color(x, y, x + width, y + height, c, c, c, c, true);
}
draw_set_alpha(1.0);