// Good source of test models:
// https://github.com/mrdoob/three.js/tree/master/examples/models/gltf

window_set_fullscreen(true);
display_set_gui_maximise();
game_set_speed(999, gamespeed_fps);
global.mouse = {
	x : 0,
	y : 0
}
cursor = cr_arrow;
#macro gmouse global.mouse
Primitive.GENERATE_WIREFRAMES = true;

camera = new CameraView();
camera.add_post_process_effect(U3D.RENDERING.PPFX.fxaa);
camera.add_post_process_effect(U3D.RENDERING.PPFX.grayscale);
camera.add_post_process_effect(U3D.RENDERING.PPFX.gamma_correction);
camera.set_render_stages(CAMERA_RENDER_STAGE.opaque);
U3D.RENDERING.PPFX.fxaa.set_enabled(false);
U3D.RENDERING.PPFX.grayscale.set_enabled(false);
U3D.RENDERING.PPFX.gamma_correction.set_enabled(false);
distance = 12;
rotation_offset = 0;
rotation_last = current_time;
rotate_camera = true;

instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.render_mode = RENDER_MODE.draw_gui;
obj_render_controller.add_camera(camera);

environment_map = undefined;

light_ambient = new LightAmbient();
light_ambient.light_intensity = 0.025;
light_ambient.ssao_strength = 4.0;
light_ambient.ssao_radius = 2.0;
obj_render_controller.add_light(light_ambient);

light_directional = new LightDirectional(quat(), vec(50 * 0.25, 60 * 0.25, 70 * 0.25));
light_directional.look_at(vec());

camera.set_position(vec(distance * dcos(25), distance * 0.5, distance * dsin(25)));

body = undefined;

material_count = 0;
model_count = 0;
mesh_count = 0;
primitive_count = 0;

animation_loop = true;
animation_smooth = true;
animation_speed = 1.0;
animation_freq = 0.033;
import_textures = true;
apply_transforms = true;

gpu_string = "";
var map = os_get_info();
if (os_type == os_windows)
	gpu_string = "GFX: " + map[? "video_adapter_description"];
else
	gpu_string = "GFX: " + (map[? "gl_renderer_string"] ?? "[unknown]");
	
if (string_pos("(", gpu_string) > 0)
	gpu_string = string_copy(gpu_string, 1, string_pos("(", gpu_string) - 1);

ds_map_destroy(map);

function update_data_count(){
	material_count = get_ref_instance_count(Material);
	model_count = get_ref_instance_count(Model);
	mesh_count = get_ref_instance_count(Mesh);
	primitive_count = get_ref_instance_count(Primitive);
}

// GameMaker's gui adjustment isn't immediate; just delay GUI element spawn for a bit
alarm[0] = 60;