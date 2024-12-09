// In the case of this demo, no delta timing and just keeping it set to 60 for simplicity
display_reset(0, true);
game_set_speed(60, gamespeed_fps);

#region PROPERTIES
render_width = display_get_gui_width();
render_height = display_get_gui_height();
	
cursor = cr_arrow;
#endregion

#region METHODS
#endregion

#region INIT
// Generate character:
instance_create_depth(0, 0, 0, obj_character);
instance_create_depth(-1, 2, 0, obj_sphere);
instance_create_depth(-1, -2, 0, obj_sphere);
obj_collision_controller.set_partition_system(new BVH());
obj_collision_controller.enable_collision_highlights(true);

obj_render_controller.set_render_mode(RENDER_MODE.draw_gui);	// Set to display in GUI just for simplicity in rendering resolution

// Load in pre-built scene:
var gltf_scene = new GLTFBuilder("demo-scene.glb");
gltf_model = gltf_scene.generate_model();
gltf_model.generate_unique_hash();
gltf_model.freeze();
camera = gltf_scene.generate_cameras()[0];
light_array = gltf_scene.generate_lights();

scene_body = new Body();
scene_body.set_model(gltf_model);
obj_render_controller.add_body(scene_body);
obj_render_controller.add_camera(camera);

camera.add_ppfx(U3D.RENDERING.PPFX.fxaa);

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

collidable_bodies = [];	// Used just to free at close
// Spawn collision shapes:
	// The demo mesh is designed to have cubes labeled as Cube_# w/ a single primitive
	// so we generate collidables for that. Looking into more automated ways of handling
	// collidable shapes from Blender.
var mesh_array = gltf_model.get_mesh_array();
for (var i = 0; i < array_length(mesh_array); ++i){
	var mesh = mesh_array[i];
	if (not string_starts_with(mesh.get_data(["import", "name"], ""), "Cube"))
		continue;
		
	var primitive = mesh_array[i].get_primitive_data(0).primitive;
	
	var extends = primitive.get_data(["import", "aabb_extends"]);
	var center = primitive.get_data(["import", "aabb_center"]);
	extends = vec_abs_max(extends, vec(0.1, 0.1, 0.1));
	center = vec_sub_vec(center, vec_sub_vec(extends, primitive.get_data(["import", "aabb_extends"])));
	
	var pbody = new Body();
	var pcol = new AABB(extends);
	pcol.generate_unique_hash();
	pbody.set_collidable(pcol);
	pcol.set_offset(pbody, center);
	obj_collision_controller.add_body(pbody);
	array_push(collidable_bodies, pbody)
}

camera_ray = new Ray();
camera_ray.generate_unique_hash();
camera_ray.set_static(camera, true);
camera.set_collidable(camera_ray);
camera.set_collision_mask_layers(2);	// Take us out of layer 1 so other objects don't detect the ray
obj_collision_controller.add_body(camera);

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

#region GUI INIT
// Right-side buttons:
var ax = display_get_gui_width() - 12 - 256;
var ay = display_get_gui_height() - 12 - 44;
var inst;
if (not U3D.OS.is_compatability){
	inst = instance_create_depth(ax, ay, 0, obj_button);
	inst.text = "Exit";
	inst.signaler.add_signal("pressed", new Callable(id, game_end));
	ay -= 44;
}

inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Partition Test";
inst.text_tooltip = "Switch to a scene focused on testing basic partitioning via block placement and mouse interaction.";
inst.signaler.add_signal("pressed", new Callable(id, function(){
	instance_destroy(obj_menu_item);
	instance_destroy(obj_character);
	instance_destroy();
	
	instance_create_depth(0, 0, 0, obj_collision_demo);
}));
ay -= 44;

inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Render Test";
inst.text_tooltip = "Switch to a scene focused on testing rendering.";
inst.signaler.add_signal("pressed", new Callable(id, function(){
	instance_destroy(obj_menu_item);
	instance_destroy(obj_character);
	instance_destroy();
	
	instance_create_depth(0, 0, 0, obj_render_demo);
}));

ax = 12;
ay = display_get_gui_height() - 12 - 44;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.is_checked = false;
inst.text = "Render Collisions";
inst.text_tooltip = "Render collision shape outlines. Color codes will relate to collision detection THAT FRAME.\n\nColor-code:\nRed: Not scanned\nGreen: Scanned, no collision\nYellow: Scanned, collision";
inst.signaler.add_signal("checked", new Callable(id, function(is_checked){
	camera.set_debug_flag(CAMERA_DEBUG_FLAG.render_collisions, is_checked);
}));

ay -= 36;

inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.is_checked = false;
inst.text = "Render Partitioning";
inst.text_tooltip = "Render collision partitioning system nodes.\n\nColor-code:\nCyan: Leaf Node\nBlue: Parent Node\n\nFor this demo, leaf nodes can contain 4 collision bodies.";
inst.signaler.add_signal("checked", new Callable(id, function(is_checked){
	camera.set_debug_flag(CAMERA_DEBUG_FLAG.render_partitions, is_checked);
}));

ay -= 36;
#endregion