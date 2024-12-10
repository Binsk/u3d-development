/// @description 
// Update mouse coordinate:
gmouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

render_width = display_get_gui_width();
render_height = display_get_gui_height();

// Set window cursor to what was calculated last frame:
window_set_cursor(cursor);

// Recalculate tooltip and cursor icon:
cursor = cr_arrow;
with (obj_tooltip)
	text = "";
	
with (obj_menu_item){
	if (not is_hovered)
		continue;
	
	obj_tooltip.text = text_tooltip;
	other.cursor = cr_handpoint;
	break;
}