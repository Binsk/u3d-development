event_inherited();
if (not is_undefined(body)){
	var c = (obj_demo_controller.primary_button == id ? c_yellow : c_lime);
	draw_rectangle_color(x, y, x + width, y + height, c, c, c, c, true);
}