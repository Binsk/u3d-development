if (keyboard_check(vk_space))
	return;
	
if (keyboard_check(vk_up))
	distance -= 0.05 * (1.0 + keyboard_check(vk_shift) * 100);
if (keyboard_check(vk_down))
	distance += 0.05 * (1.0 + keyboard_check(vk_shift) * 100);
	
camera.set_position(vec(distance * cos(current_time / 2000), distance, distance * sin(current_time / 2000)));
camera.look_at_up(vec());
