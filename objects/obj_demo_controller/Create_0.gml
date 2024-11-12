/// DEF-spine.005	-	Left/Right
/// DEF-spine.006	-	Up/Down

// Good source of test models:
// https://github.com/mrdoob/three.js/tree/master/examples/models/gltf
#macro gmouse global.mouse
window_set_fullscreen(true);
display_set_gui_maximise();
game_set_speed(9999, gamespeed_fps);
gmouse = {
	x : 0,
	y : 0
}

cursor = cr_arrow;
Primitive.GENERATE_WIREFRAMES = true; // All generated models will have wireframe versions generated as well

// Create our camera:
camera = new CameraView();
camera.add_post_process_effect(U3D.RENDERING.PPFX.fxaa);			// Add post processing, but disable it
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

primary_button = noone;	// Model buttons contain loaded model data, this is the primary button that others get attached to

instance_create_depth(0, 0, 0, obj_animation_controller);	// Allow auto-handling animation updates
instance_create_depth(0, 0, 0, obj_render_controller);		// Allow auto-handling rendering updates
instance_create_depth(0, 0, 0, obj_collision_controller);

obj_render_controller.render_mode = RENDER_MODE.draw_gui;	// Set to display in GUI just for simplicity in rendering resolution
obj_render_controller.add_camera(camera);					// Assign our camera to be managed by the rendering system

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

animation_loop = true;		// Animation properties we will apply to the currently animated models (all global)
animation_smooth = true;
animation_speed = 1.0;
animation_freq = 0.033;
import_textures = true;
apply_transforms = true;

error_array = [];
error_time = 0;

slider_ay = 0;
model_scale_slider_array = [];

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

function push_error(message){
	error_time = current_time;
	array_push(error_array, message);
}

// GameMaker's gui adjustment isn't immediate; just delay GUI element spawn for a bit
alarm[0] = 60;

#region COLLISION TEST
// var ray = new Ray();
// var plane = new Plane();
// plane_body = new Body();
// camera.set_collidable(ray);
// plane_body.set_collidable(plane);
// obj_collision_controller.add_body(camera);
// obj_collision_controller.add_body(plane_body);
// obj_collision_controller.add_signal(camera, new Callable(id, function(array){
// 	if (not is_undefined(body)){
// 		body.set_position(array[0].get_data().intersection_point);
// 	}
// }));
#endregion

#region ANIMATION HEAD TILT TEST
channel_lr = new AnimationChannelRotation();
channel_lr.add_morph(0, veca_to_quat(veca(0, 1, 0, pi / 4))); // Left
channel_lr.add_morph(1, veca_to_quat(veca(0, 1, 0, -pi / 4))); // Right
channel_lr.freeze();

channel_ud = new AnimationChannelRotation();
channel_ud.add_morph(0, veca_to_quat(veca(1, 0, 0, pi / 6))); // Down
channel_ud.add_morph(1, veca_to_quat(veca(1, 0, 0, -pi / 3))); // Up
channel_ud.freeze();

cgroup_lr = new AnimationChannelGroup();
cgroup_lr.set_channel(channel_lr);
cgroup_ud = new AnimationChannelGroup();
cgroup_ud.set_channel(channel_ud);

animation_plane = new Plane(vec(1, 0, 0));	// Used to project mouse & detect look location
animation_plane_body = new Body();
animation_plane_body.set_position(vec(2, 0, 0));
animation_plane_body.set_collidable(animation_plane);
obj_collision_controller.add_body(animation_plane_body);

animation_ray = new Ray();	// Used for mouse projection
look_point = vec();	// Used to store the 'look point' of the collision
camera.set_collidable(animation_ray);
obj_collision_controller.add_body(camera);
obj_collision_controller.add_signal(camera, new Callable(id, function(data_array){
	look_point = data_array[0].get_data().intersection_point;
}));

animation_lr = 0.5;
animation_ud = 0.5;
#endregion