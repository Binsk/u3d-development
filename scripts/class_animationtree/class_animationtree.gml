/// @about
/// An AnimationTree() is responsible for interpolating and/or stacking a number
/// of AnimationTracks() together to allow smooth track transitions and combined
/// animations. When animating a model an AnimationTree() is necessary, even if
/// the tree only contains a single animation track.
///
/// Note that, for performance reasons, animations should be auto-managed via
/// obj_animation_controller. It is possible to handle them manually, however
/// the controller can optimize out redundant transforms and calling states 
/// directly from this class requires a full re-calculation of all animation
/// tracks that are active.

/// @param	{real}	update_freq=0.033		how frequently the animation should be re-calculated (in seconds); defaults to 30fps
function AnimationTree(update_freq=0.033) : U3DObject() constructor {
	#region PROPERTIES
	track_struct = {};	// Contains name -> AnimationTrack pairs
	skeleton = {};		// Bone relation look-up map
	self.update_freq = update_freq;
	update_last = current_time * 0.001 - update_freq;
	transform_data = U3D.RENDERING.ANIMATION.skeleton_missing;	// Last cached transform data
	animation_layers = {};
	
/// @stub	Track to use until we add the layer system
	test_track = "";
	#endregion
	
	#region METHODS
	/// @desc	How many seconds must pass before the bone matrices are re-calculated.
	function set_update_freq(seconds=0.033){
		update_freq = max(0, real(seconds));
	}
	
	/// @desc	Sets the bone-relation map, a specially formatted struct where
	///			key = bone id and value = {parent_id, child_id_array}
	function set_skeleton(skeleton){
		self.skeleton = skeleton;
	}
	
	/// @desc	Returns an array of track names currently contained within
	///			this animation tree.
	function get_track_names(){
		return struct_get_names(track_struct);
	}
	
	/// @desc	Given the name of a track, returns the number of bones that are
	///			being morphed by the track.
	function get_track_bone_count(track_name){
		var track = track_struct[$ track_name];
		if (is_undefined(track))
			return 0;
		
		return track.get_bone_count();
	}
	
	/// @desc	Given the name of a track, returns the number of bones that are
	///			being morphed by the track.
	function get_track_channel_count(track_name){
		var track = track_struct[$ track_name];
		if (is_undefined(track))
			return 0;
		
		return track.get_channel_count();
	}
	
	/// @desc	Returns the maximum number of bones any single track will
	///			transform.
	function get_max_bone_count(){
		var keys = struct_get_names(track_struct);
		var count = 0;
		for (var i = array_length(keys) - 1; i >= 0; --i)
			count = max(count, track_struct[$ keys[i]].get_bone_count());
		
		return count;
	}
	
	/// @desc	Returns an array of root IDs (there can be > 1)
	function get_root_bone_ids(){
		var bone_count = get_max_bone_count();
		var root_array = [];
		for (var i = 0; i < bone_count; ++i){
			var bone = skeleton[$ i];
			if (is_undefined(bone))
				continue;
				
			if (bone.parent_id < 0)
				array_push(root_array, i);
		}
		
		return root_array;
	}
	
	/// @desc	Returns a cached transform array.
	function get_transform_array(){
/// @stub	This function should always return a track WITHOUT processing!
///			We are processing here for testing, but it should be handled by the
///			animation handler automatically (to open the doors for multi-threading later)\
		var ct = current_time * 0.001;
		if (ct - update_last < update_freq)
			return transform_data;

		process(); // Update skeleton
		return transform_data;
	}
	
	function get_animation_layer_exists(animation_layer){
		return not is_undefined(animation_layers[$ real(animation_layer)]);
	}
	
	function get_animation_layer_track_name(animation_layer){
		if (not get_animation_layer_exists(animation_layer))
			return "";
		
		var data = animation_layers[$ real(animation_layer)];
		if (data.type == 0)
			return data.track_from;
		else if (data.type == 1)
			return data.track;
		
		return "";
	}
	
	/// @desc	Given calculated TRS data for each bone, builds a 1D flattened
	///			array of all matrices built from the data, formatted to be sent
	///			into a shader.
/// @stub	This can be cached and greatly optimised, but right now it just re-calculates
///			everything.
	function generate_transform_array(trs_data){
		// Build local-space matrices:
		var keys = struct_get_names(trs_data);
		var matrix_data = {};
		for (var i = array_length(keys) - 1; i >= 0; --i){
			var data = trs_data[$ keys[i]];
			var matrix_t = matrix_build_translation(data.position.x, data.position.y, data.position.z);
			var matrix_r = matrix_build_quat(data.rotation.x, data.rotation.y, data.rotation.z, data.rotation.w);
			var matrix_s = matrix_build_scale(data.scale.x, data.scale.y, data.scale.z);
			var matrix = matrix_multiply_post(matrix_t, matrix_r, matrix_s);
			matrix_data[$ keys[i]] = matrix;
		}
		
		// Loop through bones and multiply matrices by parents
		var root_bone_ids = get_root_bone_ids();
		if (array_length(root_bone_ids) <= 0)
			throw new Exception("unable to determine root bone!");
			
		var queue = ds_queue_create();
		for (var i = 0; i < array_length(root_bone_ids); ++i)
			ds_queue_enqueue(queue, root_bone_ids[i]);
		
		while (not ds_queue_empty(queue)){
			var bone_id = ds_queue_dequeue(queue);
			var bone_data = skeleton[$ bone_id];
			
			// Add children to the queue:
			for (var i = array_length(bone_data.child_id_array) - 1; i >= 0; --i)
				ds_queue_enqueue(queue, bone_data.child_id_array[i]);
			
			// Transform parent's matrix:
			if (bone_data.parent_id < 0) // No need to transform if root
				continue;
			
			var matrix = matrix_data[$ bone_id];
			var matrix_parent = matrix_data[$ bone_data.parent_id];
			matrix_data[$ bone_id] = matrix_multiply(matrix, matrix_parent);
		}
		
		ds_queue_destroy(queue);
		
		// Apply inverse matrices:
		for (var i = array_length(keys) - 1; i >= 0; --i){
			var matrix = matrix_data[$ keys[i]];
			var matrix_inv = skeleton[$ keys[i]].matrix_inv;
			matrix_data[$ keys[i]] = matrix_multiply(matrix_inv, matrix);
		}
		
		// Write data into final array:
		var array = array_flatten(array_create(get_max_bone_count(), matrix_build_identity()));
		for (var i = array_length(keys) - 1; i >= 0; --i){
			var bone_id = keys[i];
			var matrix = matrix_data[$ bone_id];
			var offset = real(bone_id) * 16;
			 for (var j = 0; j < 16; ++j)
				array[offset + j] = matrix[j];
		}
		
		return array;
	}
	
	function add_animation_track(track){
		if (not is_instanceof(track, AnimationTrack))
			throw new Exception("invalid type, expected [AnimationTrack]!");
		
		replace_child_ref(track, track_struct[$ track.get_name()]);
		track_struct[$ track.get_name()] = track;
	}
	
	/// @desc	Creates a new animation layer to calculate. This will automatically animate through
	///			the track at a set speed without any further input.
	///	@note	Layers are paused by default and must be manually started.
	///	@note	Layers are merged from lowest index to highest; index number can be arbitrary
	/// @note	Only ONE LAYER per index! If you re-assign an index, the old layer is lost
	function add_animation_layer_auto(layer_index, track_name, track_speed=1.0){
		layer_index = real(layer_index);
		if (not is_undefined(animation_layers[$ layer_index]))
			delete animation_layers[$ layer_index];
		
		var animation_layer = {
			type : 0,
			track_from : track_name,
			track_to : undefined,
			track_speed : track_speed,
			track_loop : false,
			track_time : undefined,
			track_is_active : false,
			track_lerp : 0,
			track_lerp_length : 0
		};
		animation_layers[$ layer_index] = animation_layer;
	}
	
	/// @desc	Removes an animation layer, if it exists.
	function delete_animation_layer(layer_index){
		layer_index = real(layer_index);
		if (not is_undefined(animation_layers[$ layer_index])){
			delete animation_layers[$ layer_index];
			struct_remove(animation_layers, layer_index);
		}
	}
	
	/// @desc	Queues a track on an auto layer to be transitioned to smoothly.
	///			If the track is already transitioning, the old transition will be instantly
	///			finished and the new one started.
	///	@param	{int}		layer_index		index of the layer to queue on
	/// @param	{string}	track_name		name of the track to transition to
	/// @param	{real}		lerp_length=1.0	number of seconds the transition should take
	function queue_animation_layer_transition(layer_index, track_name, lerp_length=1.0){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		if (not is_undefined(data.track_to))
			data.track_from = data.track_to;
			
		data.track_to = track_name;
		data.track_lerp = 0;
		data.track_lerp_length = lerp_length;
	}
	
	/// @desc	Starts the animation on an 'auto' layer. Does nothing for a manual layer.
	function start_animation_layer(layer_index, loop=true){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_time ??= 0;
		data.track_is_active = true;
		data.track_loop = loop;
	}
	
	function stop_animation_layer(layer_index){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_time = undefined;
		data.track_is_active = false;
	}
	
	function pause_animation_layer(layer_index){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_is_active = false;
	}
	
	function resume_animation_layer(layer_index){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_is_active = true;
		if (is_undefined(data.track_time))
			start_animation_layer(layer_index);
	}
	
	function set_animation_layer_loops(layer_index, loop=true){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_loop = loop;
	}
	
	/// @desc	Interpolates between two sets of TRS data.
	function interpolate_trs_data(trs_data_a, trs_data_b, lerpvalue){
		var trs_data = {};
		
		var keys_a = struct_get_names(trs_data_a);
		var keys_b = struct_get_names(trs_data_b);
		// Loop first set:
		for (var i = array_length(keys_a) - 1; i >= 0; --i){
			var value_from = trs_data_a[$ keys_a[i]];
			var value_to = trs_data_b[$ keys_a[i]];
			if (is_undefined(value_to))
				trs_data[$ keys_a[i]] = value_from;
			else {
				trs_data[$ keys_a[i]] = {
					position : vec_lerp(value_from.position, value_to.position, lerpvalue),
					rotation : quat_slerp(value_from.rotation, value_to.rotation, lerpvalue),
					scale : vec_lerp(value_from.scale, value_to.scale, lerpvalue)
				}
			}
		}
		
		// Loop second set in case first set is missing some:
		for (var i = array_length(keys_b) - 1; i >= 0; --i){
			var value_from = trs_data_a[$ keys_b[i]];
			var value_to = trs_data_b[$ keys_b[i]];
			if (is_undefined(value_from))
				trs_data[$ keys_a[i]] = value_to;
			else {
				trs_data[$ keys_a[i]] = {
					position : vec_lerp(value_from.position, value_to.position, lerpvalue),
					rotation : quat_slerp(value_from.rotation, value_to.rotation, lerpvalue),
					scale : vec_lerp(value_from.scale, value_to.scale, lerpvalue)
				}
			}
		}
		
		return trs_data;
	}
	
	/// @desc	Merges two sets of TRS data evenly so they affect each-other.
	function merge_trs_data(trs_data_a, trs_data_b){
/// @stub	Implement properly
		return trs_data_a;
		// var trs_data = {};
		
		// var keys_a = struct_get_names(trs_data_a);
		// var keys_b = struct_get_names(trs_data_b);
		// // Loop first set:
		// for (var i = array_length(keys_a) - 1; i >= 0; --i){
		// 	var value_from = trs_data_a[$ keys_a[i]];
		// 	var value_to = trs_data_b[$ keys_a[i]];
		// 	if (is_undefined(value_to))
		// 		trs_data[$ keys_a[i]] = value_from;
		// 	else {
		// 		trs_data[$ keys_a[i]] = {
		// 			position : vec_add_vec(value_from.position, value_to.position),
		// 			rotation : quat_mul_quat(value_from.rotation, value_to.rotation),
		// 			scale : vec_mul_vec(value_from.scale, value_to.scale)
		// 		}
		// 	}
		// }
		
		// // Loop second set in case first set is missing some:
		// for (var i = array_length(keys_b) - 1; i >= 0; --i){
		// 	var value_from = trs_data_a[$ keys_b[i]];
		// 	var value_to = trs_data_b[$ keys_b[i]];
		// 	if (is_undefined(value_from))
		// 		trs_data[$ keys_a[i]] = value_to;
		// 	else {
		// 		trs_data[$ keys_a[i]] = {
		// 			position : vec_add_vec(value_from.position, value_to.position),
		// 			rotation : quat_mul_quat(value_from.rotation, value_to.rotation),
		// 			scale : vec_mul_vec(value_from.scale, value_to.scale)
		// 		}
		// 	}
		// }
		
		// return trs_data;
	}
	
	function process(){
		var priority = ds_priority_create();
		var keys = struct_get_names(animation_layers);
		for (var i = array_length(keys) - 1; i >= 0; --i)
			ds_priority_add(priority, animation_layers[$ keys[i]], real(keys[i]));
		
		var array = array_create(array_length(keys));
		var index = 0;
		while (not ds_priority_empty(priority))
			array[index++] = ds_priority_delete_min(priority);
			
		var trs_final = undefined;
		var ct = current_time * 0.001;
		for (var i = 0; i < index; ++i){
			var animation_layer = array[i];
			if (animation_layer.type == 0){ // Auto
				var track_from = track_struct[$ animation_layer.track_from];
				if (is_undefined(track_from)){
					print_traced("WARNING", $"invalid animation track [{track_from}]");
					continue;
				}
				
				// Update time
				var time = 0;
				if (not is_undefined(animation_layer.track_time)){
					time = animation_layer.track_time;
					if (animation_layer.track_is_active)
						time += (ct - update_last) * animation_layer.track_speed;
						
					var time_max = track_from.get_track_length();
					if (animation_layer.track_loop and time_max > 0)
						time = modwrap(time, time_max);
					else
						time = clamp(time, 0, time_max);
					
					animation_layer.track_time = time;
				}
				
				// Calculate transforms:
				var trs_data = track_from.get_trs_array_time(time);
				
				// Calculate transition, if one is set:
				var track_to = track_struct[$ animation_layer.track_to];
				if (not is_undefined(track_to)){
					var lerp_delta = (ct - update_last) / animation_layer.track_lerp_length;
					animation_layer.track_lerp += lerp_delta;
					var time2 = animation_layer.track_lerp * animation_layer.track_lerp_length * animation_layer.track_speed;
					var time_max = track_to.get_track_length();
					if (animation_layer.track_loop and time_max > 0)
						time2 = modwrap(time2, time_max);
					else
						time2 = clamp(time2, 0, time_max);
					
					trs_data = interpolate_trs_data(trs_data, track_to.get_trs_array_time(time2) , clamp(animation_layer.track_lerp, 0, 1));
						// If finished lerp, reset channel to new track:
					if (animation_layer.track_lerp >= 1){
						animation_layer.track_lerp = 0;
						animation_layer.track_lerp_length = 0;
						animation_layer.track_from = animation_layer.track_to;
						animation_layer.track_to = undefined;
						animation_layer.track_time = time2;
					}
				}
				
				// Merge transforms:
				if (is_undefined(trs_final))
					trs_final = trs_data;
				else
					trs_final = merge_trs_data(trs_final, trs_data);
			}
			else if (animation_layer.type == 1){ // Manual lerp
				
			}
			else
				throw new Exception($"invalid animation layer type [{animation_layer.type}]");
		}
		
		ds_priority_destroy(priority);
		
		if (not is_undefined(trs_final))
			transform_data = generate_transform_array(trs_final);
		else
			transform_data = U3D.RENDERING.ANIMATION.skeleton_missing;
		
		update_last = ct;
	}
	#endregion
}