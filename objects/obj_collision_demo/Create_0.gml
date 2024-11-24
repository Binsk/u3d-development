display_reset(0, false);

#region PROPERTIES
// Define render size (will be auto-updated w/ the GUI)
render_width = display_get_gui_width();
render_height = display_get_gui_height();
	
cursor = cr_arrow;
environment = new TextureCube(sprite_get_texture(spr_white_environment_demo, 0), 128);

camera = new CameraView();
camera_ray = new Ray();	// This ray will be set to the mouse position in 3D space
camera_ray.set_static(camera, true);	// Mark as static under ownership of the camera, so the camera doesn't effect the ray's orientation

light_ambient = new LightAmbient();
light_directional = new LightDirectional(vec_to_quat(vec(-1, -1, 1)), vec(5, 5, -5));

plane_body = new Body();	// Used for the 'click plane' detection
plane_collidable = new Plane();

body_array = [];	// Array of physics bodies

gltf_box = new GLTFBuilder("demo-box.glb");

body_floor = new Body(); // Done simply for shadow casting
model_floor = undefined;
#endregion

#region METHODS
#endregion

#region INIT
instance_create_depth(0, 0, 0, obj_render_controller);
instance_create_depth(0, 0, 0, obj_collision_controller);
instance_create_depth(0, 0, -2, obj_tooltip); // Tooltip only displays if it has set text
obj_collision_controller.enable_collision_highlights(true);	// Highlight collision shapes yellow when a collision is detected

// RENDERING
obj_render_controller.add_camera(camera);
obj_render_controller.add_light(light_ambient);
obj_render_controller.add_light(light_directional);
obj_render_controller.set_render_mode(RENDER_MODE.draw_gui);	// Set to display in GUI just for simplicity in rendering resolution
camera.get_eye().set_zfar(10);
camera.set_debug_flag(CAMERA_DEBUG_FLAG.render_collisions); // Mark to render collisions shapes ()
camera.set_position(vec(-2.5, 2.5, -2.5));
camera.look_at_up(vec());
camera.add_ppfx(U3D.RENDERING.PPFX.skybox, 1);
camera.add_ppfx(U3D.RENDERING.PPFX.fog, 2);
U3D.RENDERING.PPFX.skybox.set_environment_texture(environment);
U3D.RENDERING.PPFX.skybox.set_enabled(true);
U3D.RENDERING.PPFX.fog.set_color(make_color_rgb(99, 99, 99), 1.0, false);

light_ambient.set_intensity(0.1);
light_directional.set_intensity(2);
light_directional.set_casts_shadows(true);
light_directional.set_shadow_properties(2048, 24, 0.0005, 0.01, 18);

var gltf = new GLTFBuilder("demo-collision-floor.glb");
model_floor = gltf.generate_model();
body_floor.set_model(model_floor);
obj_render_controller.add_body(body_floor);

// COLLISIONS
obj_collision_controller.add_body(plane_body);
obj_collision_controller.add_body(camera);	// Add the camera's ray into the collision system

plane_collidable.generate_unique_hash(); // Mark to have memory auto-managed by the body it is added to
plane_body.set_collidable(plane_collidable);

camera_ray.generate_unique_hash();
camera.set_collidable(camera_ray);

#region GUI INIT

// Right-side buttons:
var ax = display_get_gui_width() - 12 - 256;
var ay = display_get_gui_height() - 12 - 44;
var inst;
inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Exit";
inst.signaler.add_signal("pressed", new Callable(id, game_end));

ay -= 44;
inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Render Test";
inst.text_tooltip = "Switch to a scene focused on testing rendering.";
inst.signaler.add_signal("pressed", new Callable(id, function(){
	instance_destroy(obj_menu_item);
	instance_destroy();
	
	instance_create_depth(0, 0, 0, obj_render_demo);
}));

// Left-side options:
ax = 12;
ay = display_get_gui_height() - 12 - 44;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.is_checked = true;
inst.text = "Render Collisions";
inst.signaler.add_signal("checked", new Callable(id, function(is_checked){
	camera.set_debug_flag(CAMERA_DEBUG_FLAG.render_collisions, is_checked);
}));
#endregion

#region MOUSE INTERACTION
	// Collision ray detection w/ mouse:
obj_collision_controller.add_signal(camera, new Callable(id, function(data_array){
	if (not mouse_check_button_pressed(mb_left))
		return;
	
	if (cursor != cr_arrow) // We are hovering a menu item; skip
		return;
	
	if (array_length(data_array) > 1)	// If only 1, we hit the plane. If > 1 we are hitting other boxes
		return;

	// Spawn a new box model:
	var model = gltf_box.generate_model();
	var body = new Body();
	body.set_model(model);
	var bounds = model.get_data("import");
	var aabb_size = vec_sub_vec(bounds.aabb_max, bounds.aabb_min);
	aabb_size = vec_mul_scalar(aabb_size, 0.5);
	var collidable = new AABB(aabb_size);
	body.set_collidable(collidable);
	
	var data = data_array[0]; // Collision data
	// Set the body up onto the plane (Boxes are 0.5 in scale, centered, so offset up by half a box)
	body.set_position(vec_add_vec(data.get_intersection_point(), vec(0, 0.25, 0)));
	
	array_push(body_array, body);
	
	obj_render_controller.add_body(body);
	obj_collision_controller.add_body(body);
}));
#endregion

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