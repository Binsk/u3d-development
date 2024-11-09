/// @description 
if (instance_exists(obj_bone_scroll))
	return;
	
is_hovered = point_in_rectangle(gmouse.x, gmouse.y, x, y, x + width, y + height);

if (is_hovered and mouse_check_button_pressed(mb_left)){
	if (is_model_button){
		if (is_undefined(body)){
			gltf = new GLTFBuilder(text, "test-models");
			animation_tree = gltf.generate_animation_tree();
			model = gltf.generate_model(0, obj_demo_controller.import_textures, obj_demo_controller.apply_transforms);
			model.freeze();
			
			body = new Body();
			body.set_model(model);
			if (not is_undefined(animation_tree)){
				body.set_animation(animation_tree);
				animation_tree.set_update_freq(obj_demo_controller.animation_freq);
			}
			
			var generate_as_primary = true;
			if (obj_demo_controller.primary_button != noone){ // Attempt to attach to currently active model
				if (not is_undefined(obj_demo_controller.primary_button.animation_tree)){
					// Create the bone scroll list; it will be responsible for attaching + adding model to rendering
					instance_create_depth(0, 0, -1, obj_bone_scroll);
					obj_bone_scroll.bone_name_array = obj_demo_controller.primary_button.animation_tree.get_bone_names();
					obj_bone_scroll.child_body = body;
					generate_as_primary = false;
				}
			}
			
			if (generate_as_primary){
				if (obj_demo_controller.primary_button == noone)
					obj_demo_controller.primary_button = id;
					
				var min_vec = model.get_data("aabb_min", vec());
				var max_vec = model.get_data("aabb_max", vec());
				var max_comp = vec_max_component(vec_sub_vec(max_vec, min_vec));
				
				body.set_scale(vec(10 / max_comp, 10 / max_comp, 10 / max_comp)); // Scale to fit in camera
				body.set_position(vec_mul_scalar(vec_lerp(min_vec, max_vec, 0.5), -10 / max_comp)); // Reorient to center
				obj_render_controller.add_body(body);
				obj_demo_controller.update_data_count();
			}
	
			gltf.free();
			delete gltf;
			
			// Generate slider:
			var slider = instance_create_depth(12, 0, 0, obj_slider);
			slider.text = $"{text} scale: {body.scale.x}x";
			slider.button_id = id;
			slider.min_value = body.scale.x * 0.25;
			slider.max_value = body.scale.x * 2.0;
			slider.drag_value = (body.scale.x - slider.min_value) / (slider.max_value - slider.min_value);
			slider.signaler.add_signal("drag", new Callable(id, function(value, inst, label){
				var lerpvalue = lerp(inst.min_value, inst.max_value, value);
				body.set_scale(vec(lerpvalue, lerpvalue, lerpvalue));
				inst.text = $"{text} scale: {lerpvalue}x";
			}, [undefined, slider, $"{text} scale:"]))
			array_push(obj_demo_controller.model_scale_slider_array, slider);
			slider_id = slider;
			with (obj_bone_scroll)
				slider_id = slider;
		}
		else {
			if (obj_demo_controller.primary_button != id)
				cleanup_model();
			else {
				with (obj_button)
					cleanup_model();
				
				obj_demo_controller.primary_button = noone;
			}
		}
	
		var minimum_y = 0; // Used to align floor height
		var body_index = -1;
		if (not is_undefined(obj_demo_controller.body))
			body_index = obj_demo_controller.body.get_index();
			
		var body_array = obj_render_controller.build_render_body_array(-1);
		for (var i = 0 ; i < array_length(body_array); ++i){
			var sbody = body_array[i];
			if (sbody.get_index() == body_index)
				continue;
				
			minimum_y = min(minimum_y, sbody.position.y + sbody.model_instance.get_data("aabb_min", vec()).y * sbody.scale.y);
		}
		obj_demo_controller.body_y = minimum_y;
		if (not is_undefined(obj_demo_controller.body))
			obj_demo_controller.body.set_position(vec(0, minimum_y, 0));
	}

	signaler.signal("pressed");
}
	