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
}
#endregion

#region INIT
var gltf = new GLTFBuilder("demo-sophia.glb");
model = gltf.generate_model();
animation = gltf.generate_animation_tree();
animation.generate_unique_hash();
model.generate_unique_hash();
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