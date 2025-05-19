event_inherited();
/// @about
/// The collision system handles signaling when collisions occur and recording
/// data about that collision. Collisions are processed in a passive manner,
/// meaning they should not be checked directly but instead handled through
/// signals.

/// @signals
/// "collision_<id>"			(data[])	-	thrown when a body is scanned w/ collisions where <id> is the body id that triggered the update.
///												'data' is an array of CollidableData structs for all collisions with that body.
/// "collision_entered_<id>"	(data[])	-	thrown when a body enters the space of another body.
///												'data' is an array of the bodies/data stored in PartitionData that was collided with
/// "collision_exited_<id>"		(data[])	-	thrown when a body exits the space of another body.
///												Note: If a body had entered and then been freed, the 'exited' signal will occur on the
///													  next body scan.
/// "process_pre"				()			-	thrown just before processing occurs
/// "process_post"				()			-	thrown just after processing occurs

/// @stub	Add partitioning system
#region PROPERTIES
debug_collision_highlights = false; // If enabled along w/ camera debug shapes, will highlight collisions yellow for a frame when a collision occurs.
debug_scan_count = 0;				// Number of bodies scanned from the last tic

update_map = {};	// Updates queued this frame
overlap_map = {};	// Stores <body_id> -> {<body_id> : <body>} of overlapping collisions
update_delay = 0;	// Number of ms beteewn collision scan updates
update_last = 0;	// Last time there was an update (in ms)
partition_layers = {
	"default" : new Unsorted()
}
#endregion

#region METHODS
/// @desc	Sets a new partitioning system to be used for a given layer. If the layer
///			doesn't exist it will be created. If a layer does exist the old partition
///			system will transfer over the data and then be freed.
/// @note	This gives ownership of the system to this collision controller, meaning
///			it will be auto-freed and updated accordingly.
/// @param	{Partition}	partition	partition system to use
/// @param	{string}	layer		name of the layer to assign it to
function set_partition_system(partition, layer_name="default"){
	if (not is_instanceof(partition, Partition)){
		Exception.throw_conditional("invalid type, expected [Partition]!");
		return;
	}
	
	var partition_old = partition_layers[$ layer_name];
	
	// Transfer data over
	if (not is_undefined(partition_old)){
		var data_array = partition_old.get_data_array();
		for (var i = array_length(data_array) - 1; i >= 0; --i){
			partition_old.remove_data(data_array[i]);
			partition.add_data(data_array[i]);
		}
		
		// Delete old system:
		partition_old.free();
		delete partition_old;
		
		partition.optimize();
	}
	
	// Assign new system:
	partition_layers[$ layer_name] = partition;
}

/// @desc	Set the amount of delay, in ms, between collision scans.
function set_update_delay(ms=0){
	update_delay = max(ms, 0);
}

function get_partition(label){
	return partition_layers[$ label];
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

/// @desc	Adds a body to the system and in the specified partition layer.
///			The specified layer must exist otherwise an error will be thrown.
/// @param	{Body}	body		body to attach to the system
/// @param	{bool}	is_area		if true, does NOT throw collision signals, but DOES throw entered/exit signals
/// @param	{string}layer		partition layer to add to
super.register("add_body");
function add_body(body, is_area=false, partition_layer="default"){
	var partition = partition_layers[$ partition_layer];
	if (is_undefined(partition))
		throw new Exception($"invalid partition layer, [{partition_layer}]");
	
	if (not super.execute("add_body", [body]))
		return false;

	// Link body updates to queue collision re-checks
	body.signaler.add_signal("set_position", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.add_signal("set_rotation", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.add_signal("set_scale", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	
	var data = new PartitionData(body);
	partition.add_data(data);
	body.set_data($"collision.world.{id}", data);
	body.set_data($"collision.is_area.{id}", is_area);
	overlap_map[$ body.get_index()] = {};
	return true;
}

super.register("remove_body");
function remove_body(body){
	if (not super.execute("remove_body", [body]))
		return false;
	
	body.signaler.remove_signal("set_position", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.remove_signal("set_rotation", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	body.signaler.remove_signal("set_scale", new Callable(id, _signal_queue_update, [undefined, undefined, body]));
	
	var partition_data = body.get_data($"collision.world.{id}");
	if (U3DObject.get_is_valid_object(partition_data.partition))
		partition_data.partition.remove_data(body.get_data($"collision.world.{id}"));

	body.set_data($"collision.world.{id}", undefined);
	body.set_data($"collision.is_area.{id}", undefined);
	struct_remove(overlap_map, body.get_index());
	return true;
}

#region ATTACH SIGNALS
// Signals can easily be manually attached / removed, but the following functions
// handle doing so to simplify the process.

/// @desc	Attaches a callable to the system to be executed every time the body
///			is causing a collision.
///			Signal is auto-removed if the body is freed while attached.
function add_collision_signal(body, callable){
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

/// @desc	Removes an existing 'collision' signal for the specified body; requires
///			the callable originally used to define it.
function remove_collision_signal(body, callable){
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

/// @desc	Attaches a callable to the system to be executed every time the body
///			enters a fresh collision.
///			Signal is auto-removed if the body is freed while attached.
function add_entered_signal(body, callable){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	var label = $"collision_entered_{body.get_index()}";
	signaler.add_signal(label, callable);
	body.signaler.add_signal("free", new Callable(id, _signal_free_signal, [label, callable]));
	
	return label;
}

function remove_entered_signal(body, callable){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	var label = $"collision_entered_{body.get_index()}";
	signaler.remove_signal(label, callable);
	body.signaler.remove_signal("free", new Callable(id, _signal_free_signal, [label, callable]));
}

/// @desc	Attaches a callable to the system to be executed every time the body
///			enters a fresh collision.
///			Signal is auto-removed if the body is freed while attached.
function add_exited_signal(body, callable){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	var label = $"collision_exited_{body.get_index()}";
	signaler.add_signal(label, callable);
	body.signaler.add_signal("free", new Callable(id, _signal_free_signal, [label, callable]));
	
	return label;
}

function remove_exited_signal(body, callable){
	if (not is_instanceof(body, Body)){
		Exception.throw_conditional("invalid type, expected [Body]!");
		return;
	}
	
	if (not is_instanceof(callable, Callable)){
		Exception.throw_conditional("invalid type, expected [Callable]!");
		return;
	}
	
	var label = $"collision_exited_{body.get_index()}";
	signaler.remove_signal(label, callable);
	body.signaler.remove_signal("free", new Callable(id, _signal_free_signal, [label, callable]));
}
#endregion

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
	
	if (is_undefined(scan_array)){
/// @todo	Optimize out needless partition scanning; maybe even limit partitions to specific layer groups
		var partition_array = struct_get_values(partition_layers);
		for (var i = array_length(partition_array) - 1; i >= 0; --i){
			var array = partition_array[i].scan_collisions(body.get_data($"collision.world.{id}"));
			if (is_undefined(scan_array))
				scan_array = array;
			else if (array_length(array) > 0 )
				scan_array = array_concat(scan_array, array);
		}
	}
	
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
	for (var i = array_length(instance_array) - 1; i >= 0; --i){
		var body = instance_array[i];
		var data_array = process_body(body);
		
		if (array_length(data_array) > 0){ // If there were collisions then we signal them out
			if (not body.get_data($"collision.is_area.{id}", false)){
				var data_array_mod = array_duplicate_shallow(data_array);
				for (var j = array_length(data_array_mod) - 1; j >= 0; --j){ // Remove 'area' bodies
					if (data_array_mod[j].get_other_body(body).get_data($"collision.is_area.{id}"))
						array_delete(data_array_mod, j, 1);
				}
				signaler.signal($"collision_{body.get_index()}", [data_array_mod]);
			}
			
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
		
		#region ENTERED / EXITED SIGNALS
		// Signal entered / exited:
		var data = (overlap_map[$ body.get_index()] ?? {});
		var keys = struct_get_names(data);
		// Entered:
		for (var j = array_length(data_array) - 1; j >= 0; --j){
			var obody = data_array[j].get_other_body(body);
			if (not is_undefined(data[$ obody.get_index()]))
				continue;

			signaler.signal($"collision_entered_{body.get_index()}", [obody]);
		}
		
		var ndata = {};
		// Add new data:
		for (var j = array_length(data_array) - 1; j >= 0; --j){
			var obody = data_array[j].get_other_body(body);
			ndata[$ obody.get_index()] = obody;
		}
		
		// Exited:
		for (var j = array_length(keys) - 1; j >= 0; --j){
			var obody = ndata[$ keys[j]];
			if (not is_undefined(obody))	// Still exists
				continue;
			
			obody = data[$ keys[j]];
			// No longer exists; notify:
			signaler.signal($"collision_exited_{body.get_index()}", [obody]); 
		}
		overlap_map[$ body.get_index()] = ndata;
		#endregion
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