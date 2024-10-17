/// @description 
is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x, y, x + width, y + height);

if (is_hovered and mouse_check_button_pressed(mb_left)){
	if (is_undefined(gltf)){
		gltf = new GLTFBuilder(text);
		model = gltf.generate_model(obj_demo.vformat);
		model.freeze();
		body = new Body();
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