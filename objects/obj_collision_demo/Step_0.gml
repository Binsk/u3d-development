// Update mouse coordinate:
gmouse = {
	x : device_mouse_x_to_gui(0),
	y : device_mouse_y_to_gui(0)
}

render_width = display_get_gui_width();
render_height = display_get_gui_height();

// Update mouse ray:
/// @note	Mouse ray is a bit special since it is updated through the following function
///			but nothing about the body itself is actually changed. As such, we have to trigger
///			some updates manually. Normally this is handled automatically when bodies update.
camera.calculate_world_ray(gmouse.x, gmouse.y, camera_ray);	// Update the ray to the new mouse location
camera.clear_collision_data(); // Mark the camera <-> collision relations as out-of-date so the collision system will re-calculate them on next scan
obj_collision_controller.queue_update(camera);	// Mark camera as 'changed' so the collision data KNOWS to re-scan for changes

// Set window cursor to what was calculated last frame:
window_set_cursor(cursor);

// Recalculate tooltip and cursor icon:
cursor = cr_arrow;
with (obj_tooltip)
	text = "";
	
/// Bone scroll 'overlays' everything, so disable hovering and such when it exists:
with (obj_menu_item){
	if (not is_hovered)
		continue;
	
	obj_tooltip.text = text_tooltip;
	other.cursor = cr_handpoint;
	break;
}