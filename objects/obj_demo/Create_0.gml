window_set_fullscreen(true);
global.mouse = {
	x : 0,
	y : 0
}
#macro gmouse global.mouse
vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent]);

camera = new Camera();
camera.add_post_process_effect(U3D.RENDERING.PPFX.fxaa);
U3D.RENDERING.PPFX.fxaa.set_enabled(false);
distance = 12;

instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.add_camera(camera);

environment_map = undefined;

light_ambient = new LightAmbient();
light_ambient.light_intensity = 0.025;
light_ambient.ssao_strength = 4.0;
light_ambient.ssao_radius = 2.0;
obj_render_controller.add_light(light_ambient);

light_directional = new LightDirectional(quat(), vec(-50 * 0.25, 60 * 0.25, -70 * 0.25));
light_directional.look_at(vec());

camera.set_position(vec(distance * dcos(25), distance * 0.5, distance * dsin(25)));
Camera.DISPLAY_WIDTH = 1920;
Camera.DISPLAY_HEIGHT = 1080;

display_set_gui_size(Camera.DISPLAY_WIDTH, Camera.DISPLAY_HEIGHT);
obj_render_controller.render_mode = RENDER_MODE.draw_gui;

game_set_speed(999, gamespeed_fps);

// Generate GUI:
var file = file_find_first("*.glb", fa_none);
var inst;
var ax = 1920 - 12 - 256;
while (file != ""){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
file_find_close();

file = file_find_first("*.gltf", fa_none);
while (file != ""){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}

// Directional Light:
var subinst;
ax = 12;
var ay = 1080 - 12 - 24;
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
subinst.text = "Shadows";
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
inst.is_checked = true;
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