vertical_speed -= gravity_strength;	// Change fall speed
body.set_position(vec_mul_scalar(velocity, frame_delta), true);
body.set_position(vec_mul_scalar(Node.AXIS_UP, vertical_speed * (frame_delta)), true);

// Out-of-world:
if (body.position.y < -5){
	vertical_speed = 0;
	velocity = vec();
	body.set_position(vec(x, 2.5, y));
}