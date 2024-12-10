if (not instance_exists(obj_character_demo))
	return;
	
var look = input();
	
// Update speeds:
movement_speed = clamp(movement_speed, 0, maximum_speed);	// Change run speed
vertical_speed -= gravity_strength;	// Change fall speed

// Update rotation / position
if (not vec_is_zero(look)){
	var rot_lerp = 0.1;
	if (vec_angle_difference(body.get_forward_vector(), vec_normalize(look)) > pi / 2)
		rot_lerp = 0.25;
		
	var rot = vec_lerp(body.get_forward_vector(), vec_normalize(look), rot_lerp);
	body.look_at_up(vec_add_vec(body.position, rot));
}

var position = vec_mul_scalar(body.get_forward_vector(), movement_speed * (1 / 60));
position = vec_add_vec(position, vec_mul_scalar(Node.AXIS_UP, vertical_speed * (1 / 60)));
body.set_position(position, true);

// Animation:
if (is_on_ground){ // Running / Idle animations
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

// Out-of-world:
if (body.position.y < -5){
	vertical_speed = 0;
	body.set_position(vec(0, 2, 0));
}