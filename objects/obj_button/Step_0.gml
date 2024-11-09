/// @description 
is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x, y, x + width, y + height);

if (is_hovered and mouse_check_button_pressed(mb_left)){
	if (is_model_button){
		if (is_undefined(body)){
			gltf = new GLTFBuilder(text, "test-models");
			animation_tree = gltf.generate_animation_tree();
			model = gltf.generate_model(0, obj_demo.import_textures, obj_demo.apply_transforms);
			model.freeze();
			
			body = new Body();
			body.set_model(model);
			if (not is_undefined(animation_tree)){
				body.set_animation(animation_tree);
				animation_tree.set_update_freq(obj_demo.animation_freq);
			}
			
			var generate_as_primary = true;
			if (obj_demo.primary_button != noone){ // Attempt to attach to currently active model
				if (not is_undefined(obj_demo.primary_button.animation_tree)){
					var button_id = obj_demo.primary_button;
					var bone_array = button_id.animation_tree.get_bone_names();
					// var str = get_string("Select a bone to attach to:\n\n" + string_join_ext(", ", bone_array), bone_array[0]);
					var str = bone_array[0];
					if (array_get_index(bone_array, str) >= 0){
						button_id.animation_tree.attach_body(body, button_id.body, button_id.animation_tree.get_bone_id(str));
						generate_as_primary = false;
					}
				}
			}
			
			if (generate_as_primary){
				if (obj_demo.primary_button == noone)
					obj_demo.primary_button = id;
					
				var min_vec = model.get_data("aabb_min", vec());
				var max_vec = model.get_data("aabb_max", vec());
				var max_comp = vec_max_component(vec_sub_vec(max_vec, min_vec));
				
				body.set_scale(vec(10 / max_comp, 10 / max_comp, 10 / max_comp)); // Scale to fit in camera
				body.set_position(vec_mul_scalar(vec_lerp(min_vec, max_vec, 0.5), -10 / max_comp)); // Reorient to center
			}

			gltf.free();
			delete gltf;

			obj_render_controller.add_body(body);
			obj_demo.update_data_count();
		}
		else {
			if (obj_demo.primary_button != id)
				cleanup_model();
			else {
				with (obj_button)
					cleanup_model();
				
				obj_demo.primary_button = noone;
			}
		}
	
		var minimum_y = 0; // Used to align floor height
		var body_index = -1;
		if (not is_undefined(obj_demo.body))
			body_index = obj_demo.body.get_index();
			
		var body_array = obj_render_controller.build_render_body_array(-1);
		for (var i = 0 ; i < array_length(body_array); ++i){
			var sbody = body_array[i];
			if (sbody.get_index() == body_index)
				continue;
				
			minimum_y = min(minimum_y, sbody.position.y + sbody.model_instance.get_data("aabb_min", vec()).y * sbody.scale.y);
		}
		obj_demo.body_y = minimum_y;
		if (not is_undefined(obj_demo.body))
			obj_demo.body.set_position(vec(0, minimum_y, 0));
	}
	signaler.signal("pressed");
}
	