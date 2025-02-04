if (instance_exists(obj_bone_scroll))
	return;
	
if (is_hovered and mouse_check_button_pressed(mb_left)){
	if (is_undefined(body)){ // Don't have our model loaded, so we can load now
		try{
			gltf = new GLTFBuilder(text, directory); // Loads in the model data 
			animation_tree = gltf.generate_animation_tree();	// Constructs an animation tree (if one exists)
			model = gltf.generate_model(0, obj_render_demo.import_textures, obj_render_demo.apply_transforms); // Constructs scene 0 of the model (usually all we need)
			model.freeze(); // Freeze the model into vRAM so we don't have to re-send all the vertex data every frame
			model.generate_unique_hash();
			if (not is_undefined(animation_tree))
				animation_tree.generate_unique_hash();
		}
		// Catch any glTF loading errors in this case; generally due to glTF features
		// not supported by the U3D implementation.
		catch(e){
			if (is_instanceof(e, Exception)) // It was a U3D error, print it cleanly on the screen
				obj_render_demo.push_error(e.get_message());
			else
				show_error(e, true); // If an unexpected error, let GameMaker throw a normal error
			
			// Clean up any potential left-overs
			if (is_instanceof(gltf, GLTFBuilder)){
				gltf.free();
				delete gltf;
			}
			
			if (is_instanceof(animation_tree, AnimationTree)){
				animation_tree.free();
				delete animation_tree;
			}
			
			if (is_instanceof(model, Model)){
				model.free();
				delete model;
			}
			
			return;
		}
		
		body = new Body();		// Generate a body to hold the model
		body.set_model(model);
		if (not is_undefined(animation_tree)){	// If there is animation, add it to the system as well
			body.set_animation(animation_tree);
			animation_tree.set_update_freq(obj_render_demo.animation_freq);
			// Add to the animation system for automatic updates; note that freeing the body
			// will automatically remove it from the system.
			obj_animation_controller.add_body(body);
		}
		
		if (obj_render_demo.import_lights){
			light_array = gltf.generate_lights();
			for (var i = array_length(light_array) - 1; i >= 0; --i)
				obj_render_controller.add_light(light_array[i]);
		}
		
		gltf.free();
		delete gltf;
		
		var generate_as_primary = true;
			// If a model is already loaded w/ a skeleton, we show the bone selection tree to attach
			// this body to:
		if (obj_render_demo.primary_button != noone){ // Attempt to attach to currently active model
			if (not is_undefined(obj_render_demo.primary_button.animation_tree)){
				// Create the bone scroll list; it will be responsible for attaching + adding model to rendering
				instance_create_depth(0, 0, -1, obj_bone_scroll);
				obj_bone_scroll.bone_name_array = obj_render_demo.primary_button.animation_tree.get_bone_names();
				obj_bone_scroll.child_body = body;
				generate_as_primary = false;
			}
		}
		
		// If this is the first model loaded, we want to auto-scale it to fit into view nicely 
		// and then add it to the center of the view:
		if (generate_as_primary){
			if (obj_render_demo.primary_button == noone)
				obj_render_demo.primary_button = id;
				
			var min_vec = model.get_data(["import", "aabb_min"], vec());
			var max_vec = model.get_data(["import", "aabb_max"], vec());
			var max_comp = vec_max_component(vec_sub_vec(max_vec, min_vec));
			
			body.set_scale(vec(10 / max_comp, 10 / max_comp, 10 / max_comp)); // Scale to fit in camera
			body.set_position(vec_mul_scalar(vec_lerp(min_vec, max_vec, 0.5), -10 / max_comp)); // Reorient to center
			obj_render_controller.add_body(body);
		}
		
		// Generate scaling slider:
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
		}, [undefined, slider, $"{text} scale:"]));
		
		array_push(obj_render_demo.model_scale_slider_array, slider);
		slider_id = slider;
		
		with (obj_bone_scroll)
			slider_id = slider;
	}
	else { // Model already loaded, go ahead and free the data:
		if (obj_render_demo.primary_button != id){
			is_unloading = true;
			is_disabled = true;
		}
		else { // We are the primary, free all other models in the scene as well
			with (obj_button_model){
				if (is_undefined(body))
					continue;
					
				is_unloading = true;
				is_disabled = true;
				triangle_lerp -= 0.1;	// Make sure children models free first
			}
			
			obj_render_demo.primary_button = noone;
		}
	}

	// Calculate floor height to compensate for the model change:
	var minimum_y = 0; // Used to align floor height
	var body_index = -1;
	if (not is_undefined(obj_render_demo.body_floor))
		body_index = obj_render_demo.body_floor.get_index();
		
	var body_array = obj_render_controller.build_render_body_array(-1);
	for (var i = 0 ; i < array_length(body_array); ++i){
		var sbody = body_array[i];
		if (sbody.get_index() == body_index)
			continue;
			
		minimum_y = min(minimum_y, sbody.position.y + sbody.model_instance.get_data(["import", "aabb_min"], vec()).y * sbody.scale.y);
	}
	obj_render_demo.body_floor_y = minimum_y;
	if (not is_undefined(obj_render_demo.body_floor))
		obj_render_demo.body_floor.set_position(vec(0, minimum_y, 0));
}
	
	// Increment triangle 'load in' visual effect to test partial mesh rendering.
if (not is_undefined(body) and ((not is_unloading and triangle_lerp < 1) or (is_unloading and triangle_lerp > 0))){
	triangle_lerp += (is_unloading ? -frame_delta : frame_delta);
	var mesh_array = body.get_model().get_mesh_array();
	for (var i = array_length(mesh_array) - 1; i >= 0; --i){
		var mesh = mesh_array[i];
		var primitive_array = mesh.get_primitive_array();
		for (var j = array_length(primitive_array) - 1; j >= 0; --j){
			var primitive = primitive_array[j];
			var triangles = ceil(primitive.get_triangle_count() * triangle_lerp);
			mesh.set_primitive_triangle_limit(primitive, 0, triangles);
		}
	}
	
	triangle_lerp = clamp(triangle_lerp, 0, 1);
	if (triangle_lerp <= 0 and is_unloading){
		is_unloading = false;
		cleanup_model();
		is_disabled = false;
	}
}
	
event_inherited();

with (obj_render_demo){
	if (other.y > render_height * 0.5)
		other.is_hovered = false;
}