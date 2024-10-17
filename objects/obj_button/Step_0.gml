/// @description 
is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x, y, x + width, y + height);

if (is_hovered and mouse_check_button_pressed(mb_left)){
	if (is_undefined(gltf)){
		gltf = new GLTFBuilder(text);
		model = gltf.generate_model(obj_demo.vformat);
		model.freeze();
		var min_vec = model.get_data("aabb_min");
		var max_vec = model.get_data("aabb_max");
		var max_comp = vec_max_component(vec_sub_vec(max_vec, min_vec));
		body = new Body();
		body.set_scale(vec(10 / max_comp, 10 / max_comp, 10 / max_comp)); // Scale to fit in camera
		body.set_position(vec_mul_scalar(vec_lerp(min_vec, max_vec, 0.5), -10 / max_comp)); // Reorient to center
		body.set_model(model);
		obj_render_controller.add_body(body);
	}
	else {
		obj_render_controller.remove_body(body);
		body.free();
		delete body;
		model.free();
		delete model;
		gltf.free();
		delete gltf;
	}
}