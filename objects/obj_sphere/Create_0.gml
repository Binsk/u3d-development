#region PROPERTIES
body = undefined;
collidable = undefined;
model = undefined;
vertical_speed = 0;
gravity_strength = 0.25;
velocity = vec();
absorption = 0.5;	// How much momentum to remove in a collision [0..1]
#endregion

#region METHODS
function is_collision(data_array, recurse=true){ // How to handle collisions
	var velocity_addition = vec(); // How much velocity to clamp to based on colliding body velocity
	
		// Scan through collisions and see if any of the bodies have a GameMaker object assigned
	for (var i = array_length(data_array) - 1; i >= 0; --i){
		var data = data_array[i];
		var pbody = data.get_affected_body();
		var parent_id = pbody.get_data("parent_id");
		if (is_undefined(parent_id))
			continue;

		if (parent_id.object_index == obj_character)
			velocity_addition = vec_add_vec(velocity_addition, vec_mul_scalar(parent_id.body.get_forward_vector(), parent_id.movement_speed));
		else if (parent_id.object_index == obj_sphere){
			velocity_addition = vec_add_vec(velocity_addition, parent_id.velocity);
			if (recurse)
				parent_id.is_collision([CollidableDataAABB.calculate_reverse(data)], false);
		}
	}

	// Get the total push vector to move us out of the bodies:
	var push_vector = CollidableDataAABB.calculate_combined_push_vector(body, data_array);
	if (push_vector.y > 0){ // If being pushed up we hit some ground:
		vertical_speed = -vertical_speed * absorption;
		if (abs(vertical_speed < 0.05))
			vertical_speed = 0;
	}

	body.set_position(push_vector, true);	// Push out of object
	
	push_vector.y = 0; // Remove y for 'body push' effect
	if (vec_dot(push_vector, velocity) < 0){ // Bounce the body off of what it hit
		velocity = vec_reflect(velocity, vec_normalize(push_vector));
		velocity.x *= absorption;
		velocity.z *= absorption;
	}
	
	velocity = vec_add_vec(velocity, push_vector); // Push out of bodies
	velocity = vec_abs_max(velocity, velocity_addition); // Clamp to colliding body's velocity to simulate a continuous push
}
#endregion

#region INIT
body = new Body();
body.set_position(vec(x, 2.5, y));

var gltf = new GLTFBuilder("demo-sphere.glb");
model = gltf.generate_model();
model.generate_unique_hash();
model.freeze();

collidable = new Sphere(0.5);
collidable.generate_unique_hash();
collidable.set_static(body, true);

body.set_model(model);
body.set_collidable(collidable);
body.set_data("parent_id", id);	// Generic data so we can manually manage collisions a bit better

obj_render_controller.add_body(body);
obj_collision_controller.add_body(body);
obj_collision_controller.add_signal(body, new Callable(id, is_collision));

gltf.free();
delete gltf;

#endregion