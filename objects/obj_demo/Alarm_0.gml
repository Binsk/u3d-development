
instance_create_depth(0, 0, -2, obj_tooltip);

// Generate GUI:
	// Scane model files:
var file = file_find_first("test-models/*.glb", fa_none);
var inst;
var ax = display_get_gui_width() - 12 - 256;
while (file != "" and instance_number(obj_button) < 18){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
file_find_close();

file = file_find_first("test-models/*.gltf", fa_none);
while (file != "" and instance_number(obj_button) < 18){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
 
inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44, 0, obj_button);
inst.is_model_button = false;
inst.text = "Exit";
inst.signaler.add_signal("pressed", new Callable(id, game_end));

	// Global properties:
body_y = 0; // Used to update floor height
inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44 - 32, 0, obj_checkbox);
inst.text = "Render Floor";
inst.text_tooltip = "Renders a wooden floor at the base of the model.";
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked){
		if (is_undefined(body)){
			var gltf = new GLTFBuilder("demo-floor.glb");
			var model = gltf.generate_model();
			model.freeze();
			body = new Body();
			body.set_model(model);
			obj_render_controller.add_body(body);
			gltf.free();
			delete gltf;
		}
		
		obj_render_controller.add_body(obj_demo.body);
		obj_demo.body.set_position(vec(0, obj_demo.body_y, 0));
	}
	else
		obj_render_controller.remove_body(obj_demo.body);
	
	update_data_count();
});

inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44 - 64, 0, obj_checkbox);
inst.text = "Rotate Camera";
inst.text_tooltip = "Set the camera to automatically rotate around the model.";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	with (obj_demo){
		rotate_camera = is_checked;
		if (is_checked)
			rotation_offset += current_time - rotation_last;
		else
			rotation_last = current_time;
	}
});

inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44 - 96, 0, obj_checkbox);
inst.text = "Import Textures";
inst.text_tooltip = "Whether or not the included glTF textures should be imported along with the model.";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	with (obj_demo){
		import_textures = is_checked;
	}
});

inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44 - 128, 0, obj_checkbox);
inst.text = "Apply Transforms";
inst.text_tooltip = "Whether or not node transforms should be applied directly to the vertex buffers upon load.";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	with (obj_demo){
		apply_transforms = is_checked;
	}
});

inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44 - 128 - 32, 0, obj_checkbox);
inst.text = "Render Wireframe";
inst.text_tooltip = "Whether or not the model should render as a wireframe.\n\nNote: Wireframes are for debugging only as they are slow to render and require a separate vertex buffer to be generated upon model load.";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	obj_demo.camera.debug_flags = is_checked;
});


// Animation properties:
ax -= 256 + 12;
inst = instance_create_depth(ax, 12, 0, obj_checkbox);
inst.is_checked = true;
inst.text = "Loop Animations";
inst.text_tooltip = "Whether animation channels should loop or pause at the end of the track.";
inst.signaler.add_signal("checked", function(is_checked){
	obj_demo.animation_loop = is_checked;
	with (obj_button){
		if (is_undefined(animation_tree))
			continue;
		
		animation_tree.set_animation_layer_loops(0, is_checked);
	}
});

inst = instance_create_depth(ax, 12 + 32, 0, obj_checkbox);
inst.is_checked = true;
inst.text = "Smooth Transitions";
inst.text_tooltip = "Whether or not changing animation tracks should interpolate between each other smoothly.";
inst.signaler.add_signal("checked", function(is_checked){
	obj_demo.animation_smooth = is_checked;
});

inst = instance_create_depth(ax, 12 + 32 + 80, 0, obj_slider);
inst.text = "Animation Speed: 1x";
inst.text_tooltip = "Animation speed multiplier; relative to the track's inherent speed.";
inst.min_value = 0.0;
inst.max_value = 2.0;
inst.signaler.add_signal("drag", new Callable(id, function(drag_value, inst){
	var lerpvalue = lerp(inst.min_value, inst.max_value, drag_value);
	lerpvalue = floor(lerpvalue * 100) / 100;
	inst.text = $"Animation Speed: {lerpvalue}x";
	obj_demo.animation_speed = lerpvalue
	with (obj_button){
		if (is_undefined(animation_tree))
			continue;
		
		animation_tree.set_animation_layer_speed(0, lerpvalue);
	}
},  [undefined, inst]));

inst = instance_create_depth(ax, 12 + 32 + 80 + 64, 0, obj_slider);
inst.text = "Update Frequency.: 0.03s";
inst.text_tooltip = "The number of seconds between skeletal matrix updates for the animation system.";
inst.min_value = 0.016;
inst.max_value = 0.2;
inst.drag_value = 0.033 / (inst.max_value - inst.min_value);
inst.signaler.add_signal("drag", new Callable(id, function(drag_value, inst){
	var lerpvalue = lerp(inst.min_value, inst.max_value, drag_value);
	lerpvalue = floor(lerpvalue * 100) / 100;
	inst.text = $"Update Frequency: {lerpvalue}s";
	obj_demo.animation_freq = lerpvalue
	with (obj_button){
		if (is_undefined(animation_tree))
			continue;
		
		animation_tree.set_update_freq(obj_demo.animation_freq);
	}
},  [undefined, inst]));

// Directional Light:
var subinst;
ax = 12;
var ay = display_get_gui_height() - 12 - 24;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "Directional Light";
inst.text_tooltip = "Render a directional light in the scene.";
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_directional);
	else
		obj_render_controller.add_light(obj_demo.light_directional);
});

subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows";
subinst.text_tooltip = "Render directional shadows onto the scene.";
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_directional.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, subinst);

subinst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
subinst.text = "Environment";
subinst.text_tooltip = "Render environmental reflections with a pre-set dummy cube-map for the directional light.";
subinst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_demo.light_directional.set_environment_texture(undefined);
	else{
		if (is_undefined(obj_demo.environment_map))
			obj_demo.environment_map = new TextureCubeMip(sprite_get_texture(spr_default_environment_cube, 1), 1024, 2, true);
		
		obj_demo.light_directional.set_environment_texture(obj_demo.environment_map);
	}
});
array_push(inst.child_elements, subinst);

ay -= 36;

// Ambient Light
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "Ambient Light";
inst.text_tooltip = "Render a simple ambient light in the scene.";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_ambient);
	else
		obj_render_controller.add_light(obj_demo.light_ambient);
});
subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows (SSAO)";
subinst.text_tooltip = "Render screen-space ambient occlusion for the ambient light.";
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_ambient.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, subinst);

subinst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
subinst.text = "Environment";
subinst.text_tooltip = "Render environmental reflections with a pre-set dummy cube-map for the ambient light.";
subinst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_demo.light_ambient.set_environment_texture(undefined);
	else{
		if (is_undefined(obj_demo.environment_map))
			obj_demo.environment_map = new TextureCubeMip(sprite_get_texture(spr_default_environment_cube, 1), 1024, 2, true);
		
		obj_demo.light_ambient.set_environment_texture(obj_demo.environment_map);
	}
});
array_push(inst.child_elements, subinst);

ay -= 36;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text ="Opaque Pass";
inst.text_tooltip = "Whether or not opaque materials should be rendered.";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked)
		obj_demo.camera.render_stages |= CAMERA_RENDER_STAGE.opaque;
	else
		obj_demo.camera.render_stages &= ~CAMERA_RENDER_STAGE.opaque;
});

inst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
inst.text ="Translucent Pass";
inst.text_tooltip = "Whether or not translucent materials should be rendered.";
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked)
		obj_demo.camera.render_stages |= CAMERA_RENDER_STAGE.translucent;
	else
		obj_demo.camera.render_stages &= ~CAMERA_RENDER_STAGE.translucent;
});

ay -= 36
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "FXAA";
inst.text_tooltip = "Apply fast approximate anti-aliasing to the scene.";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	U3D.RENDERING.PPFX.fxaa.set_enabled(is_checked);
});

inst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
inst.text = "Grayscale";
inst.text_tooltip = "Apply a grayscale shader to the scene.";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	U3D.RENDERING.PPFX.grayscale.set_enabled(is_checked);
});

ay -= 24;
inst = instance_create_depth(ax, ay, 0, obj_slider);
inst.text = "Supersampling: 1x";
inst.text_tooltip = "Changes the native rendering resolution by multiplying this value against the base render resolution.";
inst.signaler.add_signal("drag", new Callable(id, function(drag_value, inst){
	var lerpvalue = lerp(inst.min_value, inst.max_value, drag_value);
	lerpvalue = floor(lerpvalue * 100) / 100;
	inst.text = $"Supersampling: {lerpvalue}x";
	obj_demo.camera.set_supersample_multiplier(lerpvalue)
},  [undefined, inst]));
sprite_array = [];