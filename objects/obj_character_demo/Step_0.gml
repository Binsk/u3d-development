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

// Move the platform if it is actively set to moving or if it is still returnning to its start position:
if (not is_undefined(body_platform) and (is_platform_moving or body_platform.position.x > 0.01)){
	platform_delta += frame_delta * 0.5;
	var pos = vec(sin(platform_delta) * frame_delta * 1.2, 0, 0);
	body_platform.set_position(pos, true);
}