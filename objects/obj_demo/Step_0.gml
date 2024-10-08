if (keyboard_check(vk_space))
	return;
	
if (keyboard_check(vk_up) or mouse_wheel_up())
	distance -= 0.05 * (1.0 + keyboard_check(vk_shift) * 100);
if (keyboard_check(vk_down) or mouse_wheel_down())
	distance += 0.05 * (1.0 + keyboard_check(vk_shift) * 100);

if (keyboard_check_pressed(ord("1")))
	light.set_casts_shadows(not light.casts_shadows);

camera.set_position(vec(distance * cos(current_time / 2000), distance * 0.5, distance * sin(current_time / 2000)));
camera.look_at_up(vec());
