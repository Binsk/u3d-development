/// @about
/// A scene to test different collision shapes. There is a player-controlled
/// character and simple collision reactions to play around with. Static objects
/// are loaded straight from the mode file while dynamic objects are added 
/// separately.

display_reset(0, true);
game_set_speed(999, gamespeed_fps);

#region PROPERTIES
render_width = display_get_gui_width();
render_height = display_get_gui_height();
	
cursor = cr_arrow;
#endregion

#region METHODS
#endregion

#region INIT
obj_collision_controller.set_partition_system(new BVH());	// Static things are in BVH
obj_collision_controller.set_partition_system(new Unsorted(), "dynamic"); // Dynamic in unsorted; BVH is slow to update
obj_collision_controller.enable_collision_highlights(true);

// Generate character / interactibles:
obj_render_controller.set_render_mode(RENDER_MODE.draw_gui);	// Set to display in GUI just for simplicity in rendering resolution

dummy_body = new Body();
var gltf = new GLTFBuilder("demo-gdbot.glb");
var dummy_model = gltf.generate_model();
dummy_model.freeze();
dummy_model.generate_unique_hash();
var dummy_animation = gltf.generate_animation_tree();
dummy_animation.generate_unique_hash();
dummy_animation.set_update_freq(1 / 15);

gltf.free();
delete gltf;

var import_extends = dummy_model.get_data(["import", "aabb_extends"]);
var dummy_collidable = new Capsule(import_extends.y * 2.0, vec_min_component(import_extends));
dummy_collidable.set_offset(dummy_body, vec(0, import_extends.y * 0.5 + dummy_model.get_data(["import", "aabb_center"]).y * 0.5, 0));
dummy_collidable.set_static(dummy_body, true); // Prevent AABB bound re-calc due to character rotation
dummy_collidable.generate_unique_hash();

dummy_body.set_model(dummy_model);
dummy_body.set_animation(dummy_animation);
dummy_body.set_collidable(dummy_collidable)
dummy_body.set_position(vec(3, 0, 2));
dummy_body.set_rotation(veca_to_quat(vec_to_veca(Node.AXIS_UP, -pi / 2 - pi / 4)));
dummy_body.set_data("parent_id", id);

dummy_animation.signaler.add_signal("track_end", new Callable(dummy_animation, function(){
	set_update_freq(1 / 15);
	queue_animation_layer_transition(0, "Idle", 0.25);
	set_animation_layer_loops(0, true);
}));

dummy_animation.add_animation_layer_auto(0, "Idle");
dummy_animation.start_animation_layer(0);
obj_render_controller.add_body(dummy_body);
obj_collision_controller.add_body(dummy_body);
obj_animation_controller.add_body(dummy_body);

#region LOAD DEMO SCENE
// The demo scene is set up over multiple scenes; static elements and dynamic.
// We load all the static as one model automatically. The dynamic elements we
// load manually and assign things since we have special functions for each.
gltf = new GLTFBuilder("demo-scene.glb");

// Static Elements:
scene_body_array = [];	// Used to track dynamically generated bodies for easy cleanup
scene0_model = gltf.generate_model("Static");
scene0_model.generate_unique_hash();	// Activate auto-cleanup
scene0_body = new Body();
scene0_body.set_model(scene0_model);
obj_render_controller.add_body(scene0_body);

	// Generate unique static collison shapes:
var mesh_array = scene0_model.get_mesh_array();	// Get all meshes
for (var i = array_length(mesh_array) - 1; i >= 0; --i){
	// Loop each primitive; they will be prefixed with their shape and we'll add
	// them in accordingly:
	var primitive_array = mesh_array[i].get_primitive_array();
	for (var j = array_length(primitive_array) - 1; j >= 0; --j){
		var primitive = primitive_array[j];
		var body = new Body();
		
		//	Importing saves some data in the structure for reference; we can use this
		//	data to get some bounds / positions.
		body.set_position(primitive.get_data(["import", "aabb_center"]));
		var name = primitive.get_data(["import", "name"]);
		var collidable = undefined;
		if (string_starts_with(name, "Cube"))
			collidable = new AABB(primitive.get_data(["import", "aabb_extends"]));
		else if (string_starts_with(name, "Sphere"))
			collidable = new Sphere(vec_min_component(primitive.get_data(["import", "aabb_extends"])));
		
		if (is_undefined(collidable)){ // Invalid collidable; ignore
			body.free();
			delete body;
			continue;
		}
		
		collidable.generate_unique_hash();
		body.set_collidable(collidable);
		
		obj_collision_controller.add_body(body);
		array_push(scene_body_array, body);
	}
}

// Dynamic elements:
body_platform = undefined;	// Moving platform from the dynamic objects
platform_delta = 0; // Arbitrary counter to make the platform move
is_platform_moving = false;

var scene_nodes = gltf.get_scene_nodes(gltf.get_structure_index("Dynamic", "scenes"));
for (var i = array_length(scene_nodes) - 1; i >= 0; --i){
	var node = gltf.get_structure(scene_nodes[i], "nodes");
	if (is_undefined(node[$ "mesh"]))
		continue;
	
	// We build up the model ourselves through glTF functions:
	var body = new Body();
	var mesh = gltf.generate_mesh(node[$ "mesh"], false);	// Import w/o transforms so it centers
	var model = new Model();
	model.generate_unique_hash();
	model.add_mesh(mesh);
	
	var material_array = gltf.generate_material_array();	// Note, we just add ALL materials. They are re-used; no need to worry about duplicates
	for (var j = array_length(material_array) - 1; j >= 0; --j)
		model.set_material(material_array[j], j);
	
	body.set_model(model);
	
	// We only use one primitive from the mesh:
	var primitive = mesh.get_primitive_array()[0];
	var name = primitive.get_data(["import", "name"], "");
	var collidable = undefined;
	if (string_starts_with(name, "Cube"))
		collidable = new AABB(primitive.get_data(["import", "aabb_extends"]));
	
	if (is_undefined(collidable)){ // Invalid collidable; ignore
		body.free();
		delete body;
		continue;
	}
	
	/// Note about collidable offset:
	/// The model's VERTICES are actually shifted over in the world so the body is
	/// technically at 0,0,0.  However, we can get the primitive AABB bounds which will
	/// be the center based on the vertices themselves, which we shift the collidable by.
	/// This allows the block to render in the correct spot while shifting the collidable
	/// to match.
	/// This can change depending on if you apply transforms or not and so-forth in Blender
	/// and/or when importing.
	collidable.generate_unique_hash();
	collidable.set_offset(body, primitive.get_data(["import", "aabb_center"]));
	body.set_collidable(collidable);
	
	obj_render_controller.add_body(body);
	obj_collision_controller.add_body(body, false, "dynamic");	// Add to the dynamic layer instead of BVH since it's dynamic
	array_push(scene_body_array, body);
	
	if (mesh.get_data(["import", "name"], "") == "Moving_Platform")
		body_platform = body;
}

	// Set up the hotspot for moving the platform so it moves when the character
	// stands on top:
if (not is_undefined(body_platform)){
	body_motion_trigger = new Body();
	body_motion_trigger.set_collidable(body_platform.get_collidable());	// Go ahead and share collidables
	body_motion_trigger.set_scale(vec(0.8, 0.1, 0.8));	// Scale so the collision shape scales
	var pos = body_platform.get_data("collision.offset", vec());	// A bit of a hack; we steal the collision shape's offset for the body for our position
	pos = vec_duplicate(pos);
	pos.y *= 2.05;
	body_motion_trigger.set_position(pos);
	obj_collision_controller.add_body(body_motion_trigger, true, "dynamic"); // Mark as 'area' so it doesn't do collision triggers but does enter/exit checks
	
	// Make the trigger update every time the block moves:
	body_platform.signaler.add_signal("set_position", new Callable(body_motion_trigger, function(from, to){
		set_position(vec_sub_vec(to, from), true);
	}));
}

// Camera / light
camera = gltf.generate_cameras()[0];	// We assume there is only one cam for this test
camera.add_ppfx(U3D.RENDERING.PPFX.fxaa);
U3D.RENDERING.PPFX.fxaa.set_enabled(true);
obj_render_controller.add_camera(camera);

light_array = gltf.generate_lights();
for (var i = array_length(light_array) - 1; i >= 0; --i){
	if (is_instanceof(light_array[i], LightDirectional)){
		light_array[i].set_casts_shadows(true);
		light_array[i].set_shadow_properties(U3D.OS.is_browser ? 2048 : 4048, 0.0001, 0.00001);
	}
		
	obj_render_controller.add_light(light_array[i]);
}

gltf.free();
delete gltf;
#endregion

// Add extra ambient light since Blender doesn't have one:
light_ambient = new LightAmbient();
light_ambient.set_intensity(0.2);
obj_render_controller.add_light(light_ambient);

camera_ray = new Ray();
camera_ray.generate_unique_hash();
camera_ray.set_static(camera, true);
camera.set_collidable(camera_ray);
camera.set_collision_mask_layers(2);	// Take us out of layer 1 so other objects don't detect the ray
obj_collision_controller.add_body(camera, false, "dynamic");

instance_create_depth(0, 0, 0, obj_character);
instance_create_depth(-4, 12, 0, obj_sphere);
instance_create_depth(-2, 8, 0, obj_sphere);

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
	instance_destroy();
	
	instance_create_depth(0, 0, 0, obj_collision_demo);
}));
ay -= 44;

inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Render Test";
inst.text_tooltip = "Switch to a scene focused on testing rendering.";
inst.signaler.add_signal("pressed", new Callable(id, function(){
	instance_destroy(obj_menu_item);
	instance_destroy();
	
	instance_create_depth(0, 0, 0, obj_render_demo);
}));

if (not U3D.OS.is_compatability){
	ay -= 32;
	inst = instance_create_depth(ax, ay, 0, obj_checkbox);
	inst.text = "V-Sync";
	inst.text_tooltip = "Enable full-screen V-Sync";
	inst.is_checked = true;
	inst.signaler.add_signal("checked", function(is_checked){
		display_reset(0, is_checked);
	});
}

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