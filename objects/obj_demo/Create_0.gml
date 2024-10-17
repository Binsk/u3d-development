global.mouse = {
	x : 0,
	y : 0
}
#macro gmouse global.mouse
// initialize_count = room_speed * 0.1; // Done to get around a GameMaker bug w/ loading textures
vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent]);

// var gltf = new GLTFBuilder("block.glb");
// box = gltf.generate_model(vformat);
// box.freeze();

camera = new Camera();
distance = 12;
// body = new Body();
// // body.set_scale(vec(4, 4, 4));
// body.set_model(box);

instance_create_depth(0, 0, 0, obj_render_controller);
// obj_render_controller.add_body(body);
obj_render_controller.add_camera(camera);

environment_map = new TextureCubeMip(sprite_get_texture(spr_default_environment_cube, 1), 1024, 2, true);

light_ambient = new LightAmbient();
light_ambient.set_casts_shadows(true); // Enable SSAO
light_ambient.set_environment_texture(environment_map);
light_ambient.light_intensity = 0.025;
light_ambient.ssao_strength = 4.0;
light_ambient.ssao_radius = 2.0;
obj_render_controller.add_light(light_ambient);

light_directional = new LightDirectional(quat(), vec(-50 * 0.25, 60 * 0.25, -70 * 0.25));
light_directional.look_at(vec());
light_directional.set_environment_texture(environment_map);
light_directional.set_casts_shadows(true);
obj_render_controller.add_light(light_directional);

camera.set_position(vec(distance * dcos(25), distance * 0.5, distance * dsin(25)));
Camera.DISPLAY_WIDTH = 1920;
Camera.DISPLAY_HEIGHT = 1080;

display_set_gui_size(Camera.DISPLAY_WIDTH, Camera.DISPLAY_HEIGHT);
obj_render_controller.render_mode = RENDER_MODE.draw_gui;

game_set_speed(999, gamespeed_fps);

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
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_directional);
	else
		obj_render_controller.add_light(obj_demo.light_directional);
});

subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows";
subinst.is_checked  = true;
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_directional.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, inst);

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
subinst.is_checked  = true;
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_ambient.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, inst);