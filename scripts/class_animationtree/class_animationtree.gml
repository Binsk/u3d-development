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
	
	function get_root_bone_id(){
		var bone_count = get_max_bone_count();
		for (var i = 0; i < bone_count; ++i){
			var bone = skeleton[$ i];
			if (is_undefined(bone))
				continue;
				
			if (bone.parent_id < 0)
				return i;
		}
		
		return undefined;
	}
	
	/// @desc	Returns a cached transform array.
	function get_transform_array(){
		/// @stub	Implement
		var track = track_struct[$ test_track];
		if (is_undefined(track))
			return U3D.RENDERING.ANIMATION.skeleton_missing;
		
		var ct = current_time * 0.001;

		if (ct - update_last < update_freq)
			return transform_data;
		
		update_last = ct;
		
		var tl = track.get_track_length();;
		var time = (tl == 0 ? 0 : ct % tl);
		transform_data = generate_transform_array(track.get_trs_array_time(time));
		return transform_data
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
		var root_bone_id = get_root_bone_id();
		if (is_undefined(root_bone_id))
			throw new Exception("unable to determine root bone!");
			
		var queue = ds_queue_create();
		ds_queue_enqueue(queue, root_bone_id);
		
		while (not ds_queue_empty(queue)){
			var bone_id = ds_queue_dequeue(queue);
			var bone_data = skeleton[$ bone_id];
			
			// Add children to the queue:
			for (var i = array_length(bone_data.child_id_array) - 1; i >= 0; --i)
				ds_queue_enqueue(queue, bone_data.child_id_array[i]);
			
			// Transform parent's matrix:
			if (bone_id == root_bone_id) // No need to transform if root
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
	#endregion
}