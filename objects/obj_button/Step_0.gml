/// @description 
if (instance_exists(obj_bone_scroll))
	return;
	
is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x, y, x + width, y + height);

if (is_hovered and mouse_check_button_pressed(mb_left))
	signaler.signal("pressed");
	