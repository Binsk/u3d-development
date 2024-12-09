vertical_speed -= gravity_strength;	// Change fall speed
body.set_position(vec_mul_scalar(velocity, 1 / 60), true);
body.set_position(vec_mul_scalar(Node.AXIS_UP, vertical_speed * (1 / 60)), true);

// Out-of-world:
if (body.position.y < -5){
	vertical_speed = 0;
	velocity = vec();
	body.set_position(vec(x, 2.5, y));
}