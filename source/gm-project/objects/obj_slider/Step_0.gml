if (instance_exists(obj_bone_scroll))
	return;
	
if (is_disabled){
	is_hovered = false;
	is_dragging = false;
	return;
}
	
is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x - 10, y - 12, x + 266, y + 12);
if (is_hovered and mouse_check_button_pressed(mb_left))
	is_dragging = true;
if (is_dragging and mouse_check_button_released(mb_left))
	is_dragging = false;

if (is_dragging){
	drag_value = clamp((gmouse.x - x) / 256, 0, 1);
	signaler.signal("drag", [drag_value]);
}