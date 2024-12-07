display_reset(0, true);

#region PROPERTIES
render_width = display_get_gui_width();
render_height = display_get_gui_height();
	
cursor = cr_arrow;
#endregion

#region METHODS
#endregion

#region INIT
// Generate controllers + character:
instance_create_depth(0, 0, 0, obj_render_controller);
instance_create_depth(0, 0, 0, obj_collision_controller);
instance_create_depth(0, 0, 0, obj_animation_controller);
instance_create_depth(0, 0, 0, obj_character);

obj_render_controller.set_render_mode(RENDER_MODE.draw_gui);	// Set to display in GUI just for simplicity in rendering resolution

// Load in pre-built scene:
var gltf_scene = new GLTFBuilder("demo-scene.glb");
gltf_model = gltf_scene.generate_model();
camera_array = gltf_scene.generate_cameras();
light_array = gltf_scene.generate_lights();

scene_body = new Body();
scene_body.set_model(gltf_model);
obj_render_controller.add_body(scene_body);
for (var i = min(array_length(camera_array) - 1, 0); i >= 0; --i){ // Only spawn one camera
	obj_render_controller.add_camera(camera_array[i]);
	camera_array[i].add_ppfx(U3D.RENDERING.PPFX.fxaa);
}

for (var i = array_length(light_array) - 1; i >= 0; --i){
	if (is_instanceof(light_array[i], LightDirectional)){
		light_array[i].set_casts_shadows(true);
		light_array[i].set_shadow_properties(U3D.OS.is_browser ? 2048 : 4096, 0.0001, 0.00001);
	}
		
	obj_render_controller.add_light(light_array[i]);
}

gltf_scene.free();
delete gltf_scene;

// Add extra ambient light since Blender doesn't have one:
light_ambient = new LightAmbient();
light_ambient.set_intensity(0.2);
obj_render_controller.add_light(light_ambient);

// Spawn collision shapes:
body_floor = new Body();
collidable_floor = new Plane();
body_floor.set_collidable(collidable_floor);
obj_collision_controller.add_body(body_floor);

camera_ray = new Ray();
camera_ray.set_static(camera_array[0], true);
camera_array[0].set_collidable(camera_ray);
obj_collision_controller.add_body(camera_array[0]);

// Get information about the GPU name:
gpu_string = "";
var map = os_get_info();
if (os_type == os_windows)
	gpu_string = "GFX: " + map[? "video_adapter_description"];
else
	gpu_string = "GFX: " + (map[? "gl_renderer_string"] ?? "[unknown]");
	
if (string_pos("(", gpu_string) > 0)
	gpu_string = string_copy(gpu_string, 1, string_pos("(", gpu_string) - 1);

ds_map_destroy(map);
#endregion