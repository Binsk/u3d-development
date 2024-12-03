display_reset(0, true);

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
plane_body.set_position(vec(0, 0.01, 0));

body_array = [];	// Array of physics bodies

gltf_box = new GLTFBuilder("demo-box.glb");

body_floor = new Body(); // Done simply for shadow casting
model_floor = undefined;

dragged_body = undefined;	// The body that is currently being dragged by the mouse
collidable_box = undefined;
#endregion

#region METHODS

function spawn_dead_cube(position){
	var inst = instance_create_depth(0, 0, 0, obj_collision_box_fade)
	inst.body.set_position(position);
}

/// @desc	Handle clicking on a box
function click_box_detect(data_array){
	// Delete plane from the array:
	for (var i = array_length(data_array) - 1; i >= 0; --i){
		if (data_array[i].get_affected_class() == Plane)
			array_delete(data_array, i, 1);
	}
	
	// Grab closest box:
	var data = CollidableDataRay.get_shortest_ray(camera, data_array);
	if (is_undefined(data))
		return;
	
	dragged_body = data.get_affected_body();
	plane_body.set_position(vec(0, 0.55, 0));
}

/// @desc	Handle clicking / spawning boxes:
function mouse_collision_left(data_array, pressed=true){
	if (array_length(data_array) > 1){	// If only 1, we hit the plane. If > 1 we are hitting other boxes
		if (pressed)
			click_box_detect(data_array);
		
		return;
	}
	
	if (not is_undefined(dragged_body))
		return;
	
	// Spawn a new box model:
	var model = gltf_box.generate_model();
	model.freeze();
	var body = new Body();
	body.set_model(model);
	var bounds = model.get_data("import"); // Grab any saved import data from the model
	var aabb_center = vec_add_vec(bounds.aabb_max, bounds.aabb_min);
	var aabb_size = vec_sub_vec(bounds.aabb_max, bounds.aabb_min);
	aabb_size = vec_mul_scalar(aabb_size, 0.5);
	
	collidable_box ??= new AABB(aabb_size);
	body.set_collidable(collidable_box);
	collidable_box.set_offset(body, vec_mul_scalar(aabb_center, 0.5));
	
	var data = data_array[0]; // Collision data
	// Set the body up onto the plane (Boxes are 0.5 in scale, centered, so offset up by half a box)
	body.set_position(vec_add_vec(data.get_intersection_point(), vec(0, 0.25, 0)));
	var poso = body.get_position();
	obj_collision_controller.add_body(body);

	// Push box out of other boxes:
	/// @note	This is NOT an effective way to do this; it should be done through the
	///			collision system. However this is to demonstrate how to do things manually.
	var array = obj_collision_controller.process_body(body);
	var push = CollidableDataAABB.calculate_combined_push_vector(body, array);
	var iterations = 4;
	while (not vec_is_zero(push) and --iterations > 0){
		body.set_position(push, true);
		array = obj_collision_controller.process_body(body);
		push = CollidableDataAABB.calculate_combined_push_vector(body, array);
	}
	
	if (iterations > 0){
		array_push(body_array, body);
		obj_render_controller.add_body(body);
	}
	else{
		spawn_dead_cube(vec_add_vec(poso, vec(0, 0.55, 0)));
		
		body.free();
		delete body;
	}
}

function mouse_collision_right(data_array){
	// Delete right-clicked bodies:
	for (var i = 0; i < array_length(data_array); ++i){
		var data = data_array[i];
		
		if (data.get_affected_class() == Plane) // Don't allow deleting the plane
			continue;
			
		if (U3DObject.are_equal(data.get_affected_body(), dragged_body))
			continue;
		
		var body = data.get_affected_body();
		array_delete(body_array, array_get_index(body_array, body), 1);
		
		spawn_dead_cube(body.position);
		
		body.free();
		delete body;
	}
}

#endregion

#region INIT
instance_create_depth(0, 0, 0, obj_render_controller);
instance_create_depth(0, 0, 0, obj_collision_controller);
instance_create_depth(0, 0, -2, obj_tooltip); // Tooltip only displays if it has set text
obj_collision_controller.enable_collision_highlights(true);	// Highlight collision shapes yellow when a collision is detected
MaterialSpatial.DEFAULT_DITHER_TEXTURE = U3D.RENDERING.TEXTURE.dither_blue;

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
camera.set_render_stages(CAMERA_RENDER_STAGE.mixed);

U3D.RENDERING.PPFX.skybox.set_environment_texture(environment);
U3D.RENDERING.PPFX.skybox.set_enabled(true);
U3D.RENDERING.PPFX.fog.set_color(make_color_rgb(99, 99, 99), 1.0, false);

light_ambient.set_intensity(0.1);
light_directional.set_intensity(2);
light_directional.set_casts_shadows(true);
light_directional.set_shadow_properties(4096, 0.0005);
light_directional.get_shadow_eye().set_zfar(20);
light_directional.get_shadow_eye().set_size(30, 30);

var gltf = new GLTFBuilder("demo-collision-floor.glb");
model_floor = gltf.generate_model();
body_floor.set_model(model_floor);
obj_render_controller.add_body(body_floor);
gltf.free();
delete gltf;

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
if (not U3D.OS.is_compatability){
	inst = instance_create_depth(ax, ay, 0, obj_button);
	inst.text = "Exit";
	inst.signaler.add_signal("pressed", new Callable(id, game_end));
	ay -= 44;
}

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

// Left-side options:
ax = 12;
ay = display_get_gui_height() - 12 - 44;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.is_checked = true;
inst.text = "Render Collisions";
inst.text_tooltip = "Render collision shape outlines. Color codes will relate to collision detection THAT FRAME.\n\nColor-code:\nRed: Not scanned\nGreen: Scanned, no collision\nYellow: Scanned, collision";
inst.signaler.add_signal("checked", new Callable(id, function(is_checked){
	camera.set_debug_flag(CAMERA_DEBUG_FLAG.render_collisions, is_checked);
}));

ay -= 36;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.is_checked = true;
inst.text = "Render Shadows";
inst.text_tooltip = "Whether or not to render shadows in this scene.";
inst.signaler.add_signal("checked", new Callable(id, function(is_checked){
	light_directional.set_casts_shadows(is_checked);
}));

ay -= 36;
inst = instance_create_depth(ax, ay, 0, obj_slider);
inst.text = "Collision Update Delay: 0ms";
inst.min_value = 0;
inst.max_value = 100;
inst.drag_value = 0;
inst.text_tooltip = "How many milliseconds between collision check updates.\n\nMax update is soft-limited to the current frametime due to single-threading.";
inst.signaler.add_signal("drag", new Callable(id, function(drag_value, inst){
	var lerpvalue = lerp(inst.min_value, inst.max_value, drag_value);
	inst.text = $"Collision Update Delay: {lerpvalue}ms";
	obj_collision_controller.set_update_delay(lerpvalue);
},  [undefined, inst]));
#endregion

#region MOUSE INTERACTION
	// Collision ray detection w/ mouse:
obj_collision_controller.add_signal(camera, new Callable(id, function(data_array){
	if (cursor != cr_arrow) // We are hovering a menu item; skip
		return;
	
	if (not is_undefined(dragged_body)){ // Handle box dragging
		for (var i = array_length(data_array) - 1; i >= 0; i--){
			var data = data_array[i];
			if (data.get_affected_class() != Plane)
				continue;
			
			dragged_body.set_position(vec_add_vec(vec(0, 0.25, 0), data.get_intersection_point()));
		}
	}
	
	if (mouse_check_button_pressed(mb_left)){
		mouse_collision_left(data_array, true);
		return;
	}
	
	if (mouse_check_button(mb_left) and not instance_exists(obj_collision_box_fade)){
		mouse_collision_left(data_array, false);
		return;
	}
	
	if (mouse_check_button(mb_right)){
		mouse_collision_right(data_array);
		return;
	}
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