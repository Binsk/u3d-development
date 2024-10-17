is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x, y, x + size, y + size);

if (is_hovered and mouse_check_button_pressed(mb_left)){
	is_checked = not is_checked;
	signaler.signal("checked", [is_checked]);
}