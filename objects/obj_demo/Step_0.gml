initialize_count--;
if (initialize_count > 0)
	return;
	
if (keyboard_check(vk_space))
	return;
	
if (not keyboard_check(vk_shift)){
	if (keyboard_check(vk_up) or mouse_wheel_up())
		distance -= 0.05 * (1.0 + keyboard_check(vk_shift) * 100);
	if (keyboard_check(vk_down) or mouse_wheel_down())
		distance += 0.05 * (1.0 + keyboard_check(vk_shift) * 100);
}
else {
	for (var i = 0; i < array_length(material_array); ++i){
		var material = box.get_material(i);
		if (keyboard_check(vk_up))
			material.scalar.pbr[1] = clamp(material.scalar.pbr[1] + 0.1 * frame_delta_relative, 0, 1);
		if (keyboard_check(vk_down))
			material.scalar.pbr[1] = clamp(material.scalar.pbr[1] - 0.1 * frame_delta_relative, 0, 1);
		
		if (keyboard_check(vk_right))
			material.scalar.pbr[2] = clamp(material.scalar.pbr[2] + 0.1 * frame_delta_relative, 0, 1);
		if (keyboard_check(vk_left))
			material.scalar.pbr[2] = clamp(material.scalar.pbr[2] - 0.1 * frame_delta_relative, 0, 1);
	}
}

if (keyboard_check_pressed(ord("1")))
	light.set_casts_shadows(not light.casts_shadows);

camera.set_position(vec(distance * cos(current_time / 2000), distance * 0.5, distance * -sin(current_time / 2000)));
// body.set_rotation(veca_to_quat(veca(0, 1, 0, current_time / 2000)));
camera.look_at_up(vec());

if (keyboard_check_pressed(ord("0"))){
	var gltf = new GLTFBuilder("helmet.glb");
	var model = gltf.generate_model(vformat);
	var model_body = new Body();
	model_body.set_scale(vec(4, 4, 4));
	model_body.set_model(model);
	model_body.set_position(vec(0, 2, 6));
	obj_render_controller.add_body(model_body);
}