
// Generate GUI:
	// Scane model files:
var file = file_find_first("*.glb", fa_none);
var inst;
var ax = display_get_gui_width() - 12 - 256;
while (file != "" and instance_number(obj_button) < 18){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
file_find_close();

file = file_find_first("*.gltf", fa_none);
while (file != "" and instance_number(obj_button) < 18){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
 
inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44, 0, obj_button);
inst.is_model_button = false;
inst.text = "Exit";
inst.signaler.add_signal("pressed", new Callable(id, game_end));

body_y = 0; // Used to update floor height
inst = instance_create_depth(ax, display_get_gui_height() - 12 - 44 - 32, 0, obj_checkbox);
inst.text = "Render Floor";
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
});
// Directional Light:
var subinst;
ax = 12;
var ay = display_get_gui_height() - 12 - 24;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "Directional Light";
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_directional);
	else
		obj_render_controller.add_light(obj_demo.light_directional);
});

subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows";
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_directional.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, subinst);

subinst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
subinst.text = "Environment";
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
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_ambient);
	else
		obj_render_controller.add_light(obj_demo.light_ambient);
});
subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows (SSAO)";
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_ambient.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, subinst);

subinst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
subinst.text = "Environment";
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
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked)
		obj_demo.camera.render_stages |= CAMERA_RENDER_STAGE.opaque;
	else
		obj_demo.camera.render_stages &= ~CAMERA_RENDER_STAGE.opaque;
});

inst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
inst.text ="Translucent Pass";
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked)
		obj_demo.camera.render_stages |= CAMERA_RENDER_STAGE.translucent;
	else
		obj_demo.camera.render_stages &= ~CAMERA_RENDER_STAGE.translucent;
});

ay -= 36
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "FXAA";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	U3D.RENDERING.PPFX.fxaa.set_enabled(is_checked);
});

inst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
inst.text = "Grayscale";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	U3D.RENDERING.PPFX.grayscale.set_enabled(is_checked);
});

// inst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
// inst.text = "Stereoscopy";
// inst.is_checked = false;
// inst.signaler.add_signal("checked", function(is_checked){
// 	if (is_checked){
// 		obj_demo.ppfx_red.set_enabled(true);
// 		obj_demo.ppfx_cyan.set_enabled(true);
// 		obj_render_controller.add_camera(obj_demo.camera_anaglyph);
// 		obj_demo.camera.set_anchor_blend_mode(bm_add);
// 		U3D.RENDERING.PPFX.gamma_correction.set_enabled(true);
// 		obj_demo.camera.set_tonemap(CAMERA_TONEMAP.none);
// 	}
// 	else {
// 		obj_demo.ppfx_cyan.set_enabled(false);
// 		obj_demo.ppfx_red.set_enabled(false);
// 		obj_render_controller.remove_camera(obj_demo.camera_anaglyph);
// 		obj_demo.camera.set_anchor_blend_mode(bm_normal);
// 		U3D.RENDERING.PPFX.gamma_correction.set_enabled(false);
// 		obj_demo.camera.set_tonemap(CAMERA_TONEMAP.simple);
// 	}
// });

ay -= 24;
inst = instance_create_depth(ax, ay, 0, obj_slider);
inst.text = "Supersampling: 1x";
inst.signaler.add_signal("drag", new Callable(id, function(drag_value, inst){
	var lerpvalue = lerp(inst.min_value, inst.max_value, drag_value);
	lerpvalue = floor(lerpvalue * 100) / 100;
	inst.text = $"Supersampling: {lerpvalue}x";
	obj_demo.camera.set_supersample_multiplier(lerpvalue)
},  [undefined, inst]));
sprite_array = [];