if (not instance_exists(obj_character_demo))
	return;
	
// User Input:
if (mouse_check_button(mb_left)){
	movement_speed += movement_acceleration;
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
}
else
	movement_speed = max(0, movement_speed - movement_friction);
	
if (mouse_check_button(mb_right) and is_on_ground)
	vertical_speed = jump_strength;
	
// Udates:
movement_speed = clamp(movement_speed, 0, maximum_speed);	// Change run speed
vertical_speed -= gravity_strength;	// Change fall speed
	// Update rotation
var look = vec_sub_vec(target_vector, body.position);
look.y = 0;	// Cancel out y-axis for rotation
if (not vec_is_zero(look)){
	var rot = vec_lerp(body.get_forward_vector(), vec_normalize(look), 0.1);
	body.set_rotation(vec_to_quat(rot));
}

body.set_position(vec_mul_scalar(body.get_forward_vector(), movement_speed * (1 / 60)), true);
body.set_position(vec_mul_scalar(body.get_up_vector(), vertical_speed * (1 / 60)), true);
// Animation:
if (abs(vertical_speed) <= 0.01 and body.position.y <= 0){ // Running / Idle animations
	if (movement_speed > 0){
		animation.queue_animation_layer_transition(0, "Run", 0.25);
		animation.set_animation_layer_speed(0, movement_speed / maximum_speed);
	}
	else{
		animation.queue_animation_layer_transition(0, "Idle", 0.25);
		animation.set_animation_layer_speed(0, 1.0);
	}
}
else {	// Jumping / falling animations
	animation.set_animation_layer_speed(0, 1.0);
	animation.queue_animation_layer_transition(0, vertical_speed > 0 ? "Jump" : "Fall", 0.25);
}

is_on_ground = false;