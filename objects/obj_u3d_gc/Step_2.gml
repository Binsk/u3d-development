if (enabled)
	process();

if (keyboard_check_pressed(ord("1")))
	show_debug_message(get_ref_instance_count());