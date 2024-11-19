event_inherited();
/// @about
/// The collision system handles signaling when collisions occur and recording
/// data about that collision. Collisions are processed in a passive manner,
/// meaning they should not be checked directly but instead handled through
/// signals.

/// @signals
/// "collision_<id>"	(data[])	-	thrown when a body is scanned w/ collisions where <id> is the body id that triggered the update.
///										'data' is an array of CollidableData structs for all collisions with that body.

/// @stub	Add partitioning system

debug_collision_highlights = false; // If enabled along w/ camera debug shapes, will highlight collisions yellow for a frame when a collision occurs.

update_map = {};	// Updates queued this frame

/// @desc	Requires a camera's collision debug render be enabled. This will color
///			the shape lines yellow if a collision occurred instead of green.
function enable_collision_highlights(enable=false){
	debug_collision_highlights = bool(enable);
}

super.register("add_body");
function add_body(body){
	if (not super.execute("add_body", [body]))
		return false;

	// Link body updates to queue collision re-checks
	body.signaler.add_signal("set_position", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.add_signal("set_rotation", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.add_signal("set_scale", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	return true;
}

super.register("remove_body");
function remove_body(body){
	if (not super.execute("remove_body", [body]))
		return false;
	
	body.signaler.remove_signal("set_position", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.remove_signal("set_rotation", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.remove_signal("set_scale", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
}

/// @desc	Attaches a body to the signaling system and returns the signal label that will be used.
///			Signal is auto-removed if the body is freed while attached.
function add_signal(body, callable){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	var label = $"collision_{body.get_index()}";
	signaler.add_signal(label, callable);
	body.signaler.add_signal("free", new Callable(id, _signal_free_signal, [label, callable]));
	
	return label;
}

/// @desc	Removes an existing body <-> callable signal from the system
function remove_signal(body, callable){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	var label = $"collision_{body.get_index()}";
	signaler.remove_signal(label, callable);
	body.signaler.remove_signal("free", new Callable(id, _signal_free_signal, [label, callable]));
}

/// @desc	Calculates all collisions for bodies that have been updated.
function process(){
	/// @stub	optimize forming the body array
	var instance_array = struct_get_values(update_map);
	update_map = {}; // Clear so any signals sent can re-queue for next frame

		// If debugging on AND at least 1 body moved, clear highlights (allows for pausing & viewing highlights)
	if (debug_collision_highlights and array_length(instance_array) > 0){
		var body_array = get_body_array();
		for (var i = array_length(body_array) - 1; i >= 0; --i)
			body_array[i].set_data("collision.debug_highlight", false);
	}

	var scan_array = get_body_array(); /// @stub	this is just for testing ATM
	for (var i = array_length(instance_array) - 1; i >= 0; --i){
		var body = instance_array[i];
			// Check if the body was removed after the update trigger
		if (not U3DObject.get_is_valid_object(body) or is_undefined(body_map[$ body.get_index()]))
			continue;
		
		if (is_undefined(body.collidable_instance)) // No collidable 
			continue;
		
		body.collidable_instance.transform(body); // Update body (automatically skips if already up-to-date)
		var data_array = [];

		for (var j = array_length(scan_array) - 1; j >= 0; --j){
			var body2 = scan_array[j];
			if (U3DObject.are_equal(body, body2)) // Same body, skip
				continue;
			
			if (is_undefined(body2.collidable_instance)) // Scanned body had collidable instance removed
				continue;
			
			if (body.collidable_scan_bits & body2.collidable_mask_bits == 0) // No common layers
				continue;
			
			body2.collidable_instance.transform(body2);
			var data = Collidable.calculate_collision(body.collidable_instance, body2.collidable_instance, body, body2);
			if (is_undefined(data)) // No collision
				continue;
				
			// Collision; store data
			data.body_a = body;
			data.body_b = body2;
			array_push(data_array, data);
			
			if (debug_collision_highlights){
				data.body_a.set_data("collision.debug_highlight", true);
				data.body_b.set_data("collision.debug_highlight", true);
			}
		}
		
		if (array_length(data_array) > 0) // If there were collisions then we signal them out
			signaler.signal($"collision_{body.get_index()}", [data_array]);
	}
}

/// @desc	Queues a collision update w/ the specified body. The queue will be
///			ignored if the body is not in the system by the update tick.
function queue_update(body){
	update_map[$ body.get_index()] = body;
}

function _signal_queue_update(_from, _to, body){
	queue_update(body);
}

function _signal_free_signal(label, callable){
	signaler.remove_signal(label, callable);
}