/// @about
///	A dummy box that fades out to indicate a box was unintentially destroyed.
///	Added so it doesn't look like a glitch when boxes are deleted for overlapping
///	collisions in tight spots.

body = new Body();
model = obj_collision_demo.gltf_box.generate_model();
model.generate_unique_materials();	// Give the model unique material copies we can modify
body.set_model(model);
material_alpha = 1.0;
obj_render_controller.add_body(body);