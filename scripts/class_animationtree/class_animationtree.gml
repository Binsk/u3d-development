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

function AnimationTree() : U3DObject() constructor {
	#region PROPERTIES
	track_struct = {};	// Contains name -> AnimationTrack pairs
	#endregion
	
	#region METHODS
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
	
	function add_animation_track(track){
		if (not is_instanceof(track, AnimationTrack))
			throw new Exception("invalid type, expected [AnimationTrack]!");
		
		replace_child_ref(track, track_struct[$ track.get_name()]);
		track_struct[$ track.get_name()] = track;
	}
	#endregion
}