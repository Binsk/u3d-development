is_hovered = not is_disabled and point_in_rectangle(gmouse.x, gmouse.y, x, y, x + size, y + size);

if (is_hovered and mouse_check_button_pressed(mb_left)){
	is_checked = not is_checked;
	signaler.signal("checked", [is_checked]);
}

for (var i = array_length(child_elements) - 1; i >= 0; --i)
	child_elements[i].is_disabled = not is_checked;