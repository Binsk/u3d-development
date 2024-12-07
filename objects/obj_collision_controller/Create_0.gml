event_inherited();
/// @about
/// The collision system handles signaling when collisions occur and recording
/// data about that collision. Collisions are processed in a passive manner,
/// meaning they should not be checked directly but instead handled through
/// signals.

/// @signals
/// "collision_<id>"	(data[])	-	thrown when a body is scanned w/ collisions where <id> is the body id that triggered the update.
///										'data' is an array of CollidableData structs for all collisions with that body.
/// "process_pre"		()			-	thrown just before processing occurs
/// "process_post"		()			-	thrown just after processing occurs

/// @stub	Add partitioning system
#region PROPERTIES
debug_collision_highlights = false; // If enabled along w/ camera debug shapes, will highlight collisions yellow for a frame when a collision occurs.
debug_scan_count = 0;				// Number of bodies scanned from the last tic

update_map = {};	// Updates queued this frame
update_delay = 0;	// Number of ms beteewn collision scan updates
update_last = 0;	// Last time there was an update (in ms)
partition_system = new Unsorted();
#endregion

#region METHODS
/// @desc	Sets a new partitioning system to be used. All bodies will be transfered
///			over and the old system cleared. This should generally be avoided when the
///			system is full of bodies due to performance and optimization reasons.
/// @note	This gives ownership of the system to this collision controller, meaning
///			it will be auto-freed and updated accordingly.
function set_partition_system(partition){
	if (not is_instanceof(partition, Partition)){
		Exception.throw_conditional("invalid type, expected [Partition]!");
		return;
	}
	
	// Transfer data over
	var data_array = partition_system.get_data_array();
	for (var i = array_length(data_array) - 1; i >= 0; --i){
		partition_system.remove_data(data_array[i]);
		partition.add_data(data_array[i]);
	}
	
	// Delete old system:
	partition_system.free();
	delete partition_system;
	
	// Assign new system:
	partition_system = partition;
	
	partition_system.optimize();	// Only needed in some cases if there are lots of bodies being transfered
}

/// @desc	Set the amount of delay, in ms, between collision scans.
function set_update_delay(ms=0){
	update_delay = max(ms, 0);
}

/// @desc	Return the number of bodies scanned last tic
function get_scan_count(){
	return debug_scan_count;
}

/// @desc	Requires a camera's collision debug render be enabled. This will color
///			the shape based off the collision state where:
///			red = wasn't scanned or updated
///			green = was scanned or updated, no collision
//			yellow = was scanned or updated, collision occurred
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
	
	var data = new PartitionData(body);
	partition_system.add_data(data);
	body.set_data($"collision.world.{id}", data);
	return true;
}

super.register("remove_body");
function remove_body(body){
	if (not super.execute("remove_body", [body]))
		return false;
	
	body.signaler.remove_signal("set_position", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.remove_signal("set_rotation", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.remove_signal("set_scale", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	
	partition_system.remove_data(body.get_data($"collision.world.{id}"));
	body.set_data($"collision.world.{id}", undefined);
	return true;
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

/// @desc	Scans a single body against collisions. Direct use should generally be
///			avoided as it discards any potential optimizations but this provides immediate 
///			results if needed. The body must be inside the collision system.
/// @param		{Body}	body		body with collision data to scan with
/// @param		{array}	scan_array	array of PartitionData to check against (if none supplied, auto-calculates)
/// @returns	{array}		array of CollisionData detected
function process_body(body, scan_array=undefined){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]");
		return [];
	}
	
	// Make sure the body is valid and inside the collision system:
	if (not U3DObject.get_is_valid_object(body) or is_undefined(body_map[$ body.get_index()]) or
		not U3DObject.get_is_valid_object(body.get_collidable()))
		return [];
	
	if (is_undefined(scan_array))
		scan_array = partition_system.scan_collisions(body.get_data($"collision.world.{id}"));
	
	body.get_collidable().transform(body); // Update body (automatically skips if already up-to-date)
	var data_array = [];

	for (var j = array_length(scan_array) - 1; j >= 0; --j){
		var body2 = scan_array[j].get_data();
		if (not is_instanceof(body2, Body))
			continue;
			
		if (U3DObject.are_equal(body, body2)) // Same body, skip
			continue;
		
		if (not U3DObject.get_is_valid_object(body2.get_collidable())) // Scanned body had collidable instance removed
			continue;
		
		if (body.collidable_scan_bits & body2.collidable_mask_bits == 0) // No common layers
			continue;
		
		debug_scan_count++;
		
		body2.get_collidable().transform(body2);
		var data = Collidable.calculate_collision(body.get_collidable(), body2.get_collidable(), body, body2);
		if (is_undefined(data)){ // No collision
			if (debug_collision_highlights)
				body2.set_data("collision.debug_highlight", max(1, body2.get_data("collision.debug_highlight", 1)));
				
			continue;
		}
			
		// Collision; store data
		array_push(data_array, data);
	}
	
	return data_array;
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
			body_array[i].set_data("collision.debug_highlight", 0);
	}

	debug_scan_count = 0;
	var scan_array;
	for (var i = array_length(instance_array) - 1; i >= 0; --i){
		var body = instance_array[i];
		var data_array = process_body(body);
		
		if (array_length(data_array) > 0){ // If there were collisions then we signal them out
			signaler.signal($"collision_{body.get_index()}", [data_array]);
			
			if (debug_collision_highlights){
				for (var j = array_length(data_array) - 1; j >= 0; --j){
					var data = data_array[j];
					var body1 = data.get_colliding_body();
					var body2 = data.get_affected_body();
					body1.set_data("collision.debug_highlight", max(2, body1.get_data("collision.debug_highlight", 2)));
					body2.set_data("collision.debug_highlight", max(2, body2.get_data("collision.debug_highlight", 2)));
				}
			}
		}
		else if (debug_collision_highlights)
			body.set_data("collision.debug_highlight", max(1, body.get_data("collision.debug_highlight", 1)));
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
#endregion