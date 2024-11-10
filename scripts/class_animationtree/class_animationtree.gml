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

/// @note	If there are more than 64 bones then the system will explicit bone scaling
///			to be able to fit more bones into the shader. Maximum bone count is 128.

/// @todo	Implement dual-quaternions to remove the need for the quat+pair option &
///			to have better volume-conscious skinning.

/// @signals
///	transformed_bone_<id>	(matrix)	-	Thrown when an animation transform is applied on the specified bone; matrix = local transform

/// @param	{real}	update_freq=0.033		how frequently the animation should be re-calculated (in seconds); defaults to 30fps
function AnimationTree(update_freq=0.033) : U3DObject() constructor {
	#region PROPERTIES
	track_struct = {};	// Contains name -> AnimationTrack pairs
	skeleton = {};		// Bone relation look-up map
	self.update_freq = update_freq;
	update_last = current_time * 0.001 - update_freq;
	transform_data = undefined;	// Last cached transform data
	animation_layers = {};
	attached_bodies = {};
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
		if (struct_names_count(self.skeleton) > U3D_MAXIMUM_BONES)
			transform_data = U3D.RENDERING.ANIMATION.SKELETON.missing_quatpos;
		else
			transform_data = U3D.RENDERING.ANIMATION.SKELETON.missing_matrices;
	}
	
	/// @desc	Sets whether or not the specified animation layer should loop.
	function set_animation_layer_loops(layer_index, loop=true){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_loop = loop;
	}
	
	/// @desc	Sets the speed multiplier for the specified animation layer.
	function set_animation_layer_speed(layer_index, layer_speed=1){
		layer_index = real(layer_index);
		var data = animation_layers[$ layer_index];
		if (is_undefined(data) or data.type != 0)
			return;
		
		data.track_speed = layer_speed;
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
	
	/// @desc	Returns an array of root IDs (usually just 1, but sometimes > 1)
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
	
	/// @desc	Returns an array of bone names. If a bone does not have a name it will
	///			be added as "bone_<id>"
	function get_bone_names(){
		var bone_array = struct_get_values(skeleton);
		var array = array_create(array_length(bone_array));
		for (var i = array_length(bone_array) - 1; i >= 0; --i){
			if (is_undefined(bone_array[i].name))
				array[i] = $"bone_{i}";
			else
				array[i] = bone_array[i].name;
		}
		
		return array;
	}
	
	/// @desc	Given a bone name, returns the bone index or -1 if no match is found.
	function get_bone_id(name){
		var keys = struct_get_names(skeleton);
		for (var i = array_length(keys) - 1; i >= 0; --i){
			var bone = skeleton[$ keys[i]];
			if ((bone.name ?? $"bone_{i}") == name)
				return keys[i];
		}
		return -1;
	}
	
	/// @desc	Returns a cached transform array.
	function get_transform_array(){
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
			var matrix_t = matrix_build_translation(data.position);
			var matrix_r = matrix_build_quat(data.rotation);
			var matrix_s = matrix_build_scale(data.scale);
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
			var bone_id = keys[i];
			var matrix = matrix_data[$ bone_id];
			var matrix_inv = skeleton[$ bone_id].matrix_inv;

			var nmatrix = matrix_multiply(matrix_inv, matrix);
			matrix_data[$ bone_id] = nmatrix;
			
			skeleton[$ bone_id].matrix_cached = matrix;
			signaler.signal($"transformed_bone_{bone_id}", [matrix]);
		}
		
		// Write data into final array:
		if (array_length(keys) <= U3D_MAXIMUM_BONES){
			// If not skipping, we write the whole matrix
			var array = array_flatten(array_create(get_max_bone_count(), matrix_build_identity()));
			for (var i = array_length(keys) - 1; i >= 0; --i){
				var bone_id = keys[i];
				var matrix = matrix_data[$ bone_id];
				var offset = real(bone_id) * 16;
				 for (var j = 0; j < 16; ++j)
					array[offset + j] = matrix[j];
			}
		}
		else{
			// If skipping we just need a quaternion + translation pair
			var bone_count = get_max_bone_count();
				// Create quat + translation defaults; note add an extra to the end if uneven as we are sending in as 16-value sets
			var array = array_flatten(array_create(bone_count + (bone_count % 2), [0, 0, 0, 1, 0, 0, 0, 0]));
			for (var i = array_length(keys) - 1; i >= 0; --i){
				var bone_id = keys[i];
				var matrix = matrix_data[$ bone_id];
				var translation = matrix_get_translation(matrix);
				var quaternion = matrix_get_quat(matrix);
				var offset = real(bone_id) * 8;
				array[offset] = quaternion.x;
				array[offset + 1] = quaternion.y;
				array[offset + 2] = quaternion.z;
				array[offset + 3] = quaternion.w;
				array[offset + 4] = translation.x;
				array[offset + 5] = translation.y;
				array[offset + 6] = translation.z;
			}
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
/// @stub	Implement properly. It should take data_b and add in bone data
///			that doesn't exist in data_a
		return trs_data_a;
	}
	
	/// @desc	This uses signals to attach a child body to a bone in the animation
	///			system. This does NOT update body components! It only updates the render matrix.
	///			If attached, updating the child's components becomes expensive and should be avoided.
	/// @param	{Body}		child_body					the body of the child that should be attached to the bone
	/// @param	{Node}		parent_node					the node to transform relative to (usually the body containing the animation structure)
	/// @param	{int}		bone_id						id of the bone to attach to (use bone_get_id() to use a name)
	function attach_body(child_body, parent_node, bone_id){
		if (not is_instanceof(child_body, Body)){
			Exception.throw_conditional("invalid type, expected [Body]!");
			return;
		}
		
		if (not is_instanceof(parent_node, Node)){
			Exception.throw_conditional("invalid type, expected [Node]!");
			return;
		}
		
		detach_body(child_body, bone_id); // In case it was already attached

		// Create a callable to use every time the bone updates:
		var callable_bone = new Callable(child_body, function(matrix, parent_node){
			matrix_model = matrix_multiply_post(parent_node.get_model_matrix(), matrix, get_model_matrix(true));
			matrix_inv_model = undefined;
		}, [undefined, parent_node]);
		
		// Create a callable to use every time the body updates:
		var callable_body = new Callable(self, function(_from, _to, child_index){
			var data = attached_bodies[$ child_index];
			if (is_undefined(data))
				return;
			
			var matrix = skeleton[$ data.bone_id][$ "matrix_cached"];
			if (is_undefined(matrix))
				return;
				
			data.callable_bone.call([matrix, data.parent_node]);
		}, [undefined, undefined, child_body.get_index()]);
		
		// Record the values so we can detach things easily:
		attached_bodies[$ child_body.get_index()] = {
			bone_id : bone_id,
			callable_bone : callable_bone,
			callable_body : callable_body, 
			child_body : child_body,
			parent_node : parent_node
		};
		
		// Attach the body to the animation tree:
		signaler.add_signal($"transformed_bone_{bone_id}", callable_bone);
		child_body.signaler.add_signal("free", new Callable(self, detach_body, [child_body]));
		
		// Attach the animation tree to the body's updates:
		child_body.signaler.add_signal("set_position", callable_body);
		child_body.signaler.add_signal("set_scale", callable_body);
		child_body.signaler.add_signal("set_rotation", callable_body);
	}
	
	function detach_body(child_body){
		if (not is_instanceof(child_body, Body)){
			Exception.throw_conditional("invalid type, expected [Body]!");
			return;
		}
		
		var data = attached_bodies[$ child_body.get_index()];
		if (is_undefined(data))
			return;
		
		signaler.remove_signal($"transformed_bone_{data.bone_id}", data.callable_bone);
		child_body.signaler.remove_signal("free", new Callable(self, detach_body, [child_body]));
		child_body.signaler.remove_signal("set_position", data.callable_body);
		child_body.signaler.remove_signal("set_rotation", data.callable_body);
		child_body.signaler.remove_signal("set_scale", data.callable_body);
		struct_remove(attached_bodies, child_body.get_index());
	}
	
	function process(){
/// @stub	Remove time check from here; make it handled by the animation process
		var ct = current_time * 0.001;
		if (ct - update_last < update_freq)
			return;
			
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
/// @stub	Implement
			}
			else
				throw new Exception($"invalid animation layer type [{animation_layer.type}]");
		}
		
		ds_priority_destroy(priority);
		
		if (not is_undefined(trs_final))
			transform_data = generate_transform_array(trs_final);
		else{
			if (struct_names_count(skeleton ?? {}) > U3D_MAXIMUM_BONES)
				transform_data = U3D.RENDERING.ANIMATION.SKELETON.missing_quatpos;
			else
				transform_data = U3D.RENDERING.ANIMATION.SKELETON.missing_matrices;
		}
		
		update_last = ct;
	}
	
	super.register("free");
	function free(){
		var values = struct_get_values(attached_bodies);
		for (var i = array_length(values) - 1; i >= 0; --i)
			detach_body(values[i].child_body); // Detach to clean up the signals
		
		super.execute("free");
	}
	#endregion
}