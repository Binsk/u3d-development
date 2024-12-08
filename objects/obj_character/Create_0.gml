/// This is a very simple character that just moves in their facing direction
/// and follows the mouse.

#region PROPERTIES
movement_speed = 0;
movement_acceleration = 0.5;
movement_friction = 2.0;
maximum_speed = 7.0;
gravity_strength = 0.25;
jump_strength = 6.0;
vertical_speed = 0;
target_vector = vec();	// Vector we are trying to move to
is_on_ground = true;
#endregion

#region METHODS
function collision_pre(){ // Occurs just before a collision check
	is_on_ground = false;
}

function is_collision(data_array){ // How to handle collisions
	var push_vector = CollidableDataAABB.calculate_combined_push_vector(body, data_array);
	if (push_vector.y > 0){ // Mark as on-ground for now
		is_on_ground = true;
		vertical_speed = max(0, vertical_speed);
	}
	
	body.set_position(push_vector, true);	// Push out of object
	push_vector.y = 0;
	movement_speed -= vec_magnitude(push_vector); // Not really precise; good enough for testing
}

function input(){
	// User Input:
	var is_input = false;
	if (mouse_check_button(mb_left) and obj_character_demo.cursor == cr_arrow){
		// For immediate results; this is how you would manually ping the physics server.
		// NOTICE:	It is best to let the server auto-handle as it prevents needless re-calculations, but
		//			some times you just want an immediate result instead of a signal.
			// First, update the ray from the mouse coords:
		var ray = obj_character_demo.camera_ray;	// The ray we want
		obj_character_demo.camera.calculate_world_ray(gmouse.x, gmouse.y, ray);
			// Manually ping collision shapes:
		var collision_array = obj_collision_controller.process_body(obj_character_demo.camera);
			// Grab the collision closest to the camera:
		var data = CollidableDataRay.get_shortest_ray(obj_character_demo.camera, collision_array);
			// Set that as the new target position for the character
		if (not is_undefined(data))
			target_vector = data.get_intersection_point();
		
		is_input = true;
	}

	if ((mouse_check_button(mb_right) or keyboard_check_pressed(vk_space)) and is_on_ground and obj_character_demo.cursor == cr_arrow)
		vertical_speed = jump_strength;
		
	var look = vec_sub_vec(target_vector, body.position);

		// Add keyboard input since it works way better; mouse was just for testing.
		// This moves relative to the camera direction
	if (not mouse_check_button(mb_left) and obj_character_demo.cursor == cr_arrow){
		var right_vector = obj_character_demo.camera.get_right_vector();
		var forward_vector = obj_character_demo.camera.get_forward_vector();
		var m_vec = vec();
		if (keyboard_check(vk_right))
			m_vec = vec_add_vec(m_vec, right_vector);
		if (keyboard_check(vk_left))
			m_vec = vec_sub_vec(m_vec, right_vector);
		if (keyboard_check(vk_up))
			m_vec = vec_add_vec(m_vec, forward_vector);
		if (keyboard_check(vk_down))
			m_vec = vec_sub_vec(m_vec, forward_vector);
		
		m_vec.y = 0; // Remove tilt
		look = vec_normalize(m_vec);
		if (vec_magnitude(look) > 0)
			is_input = true;
	}
	else
		look.y = 0;	// Cancel out y-axis for rotation
	
	if (is_input)
		movement_speed += movement_acceleration;
	else 
		movement_speed = max(0, movement_speed - movement_friction);
	
	return look;
}
#endregion

#region INIT
var gltf = new GLTFBuilder("demo-gdbot.glb");
model = gltf.generate_model();
animation = gltf.generate_animation_tree();
animation.generate_unique_hash();
model.generate_unique_hash();
model.freeze();

body = new Body();
body.set_position(vec(0, 2, 0));
body.set_model(model);
body.set_animation(animation);

/// @stub	Until we get a pill shape added:
collidable = new AABB(model.get_data(["import", "aabb_extends"]));
collidable.set_offset(body, model.get_data(["import", "aabb_center"]));
collidable.set_static(body, true); // Prevent AABB bound re-calc due to character rotation
body.set_collidable(collidable);

animation.add_animation_layer_auto(0, "Idle");
animation.start_animation_layer(0);

obj_render_controller.add_body(body);
obj_animation_controller.add_body(body);
obj_collision_controller.add_body(body);

obj_collision_controller.add_signal(body, new Callable(id, is_collision));
obj_collision_controller.signaler.add_signal("process_pre", new Callable(id, collision_pre));

gltf.free();
delete gltf;
#endregion