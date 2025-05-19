/// @about
/// An AnimationTrack() contains a series of AnimationGroup() instances for
/// each bone and can calculate bone transforms across all group transforms.
/// 
/// @param	{string}	name	the name of the track; will be used to activate in the AnimationTree
function AnimationTrack(name) : U3DObject() constructor {
	#region PROPERTIES
	self.name = name;
	channel_data = {};	// bone_id -> animation channel group
	channel_length = 0;	// Max length of all channels
	#endregion
	
	#region METHODS
	/// @desc	Return the current name of the track.
	function get_name(){
		return name;
	}
	
	/// @desc	Returns the number of bones defined under this track.
	/// @note	May NOT equate to the number of bones in the model.
	function get_bone_count(){
		return struct_names_count(channel_data);
	}
	
	/// @desc	Return the number of channels defined under this track.
	function get_channel_count(){
		var count = 0;
		var names = struct_get_names(channel_data);
		for (var i = array_length(names) - 1; i >= 0; --i)
			count += channel_data[$ names[i]].get_channel_count();
		
		return count;
	}
	
	/// @desc	Returns the length of the track, in seconds
	function get_track_length(){
		return channel_length;
	}
	
	/// @desc	Adds a channel group to the track and assigns it to a specific bone index.
	function add_channel_group(group, bone_index){
		if (not is_instanceof(group, AnimationChannelGroup)){
			Exception.throw_conditional("invalid type, expected [AnimationChannelGroup]!");
			return;
		}

		replace_child_ref(group, channel_data[$ bone_index]);
		channel_data[$ bone_index] = group;
		channel_length = max(channel_length, group.get_channel_length());
	}

	/// @desc	Given a lerp value between 0 and 1, returns the transforms at that point
	///			In the form of individual TRS components for each bone.
	function get_trs_data_lerp(lerpvalue){
		var keys = struct_get_names(channel_data);
		var trs_data = {};
		for (var i = array_length(keys) - 1; i >= 0; --i)
			trs_data[$ keys[i]] = channel_data[$ keys[i]].get_trs_properties_lerp(lerpvalue);
		
		return trs_data;
	}
	
	/// @desc	Given a time value through the track, returns the transforms at that point
	///			in the form of individual TRS components for each bone.
	function get_trs_data_time(time){
		var keys = struct_get_names(channel_data);
		var trs_data = {};
		for (var i = array_length(keys) - 1; i >= 0; --i)
			trs_data[$ keys[i]] = channel_data[$ keys[i]].get_trs_properties_time(time);
		
		return trs_data;
	}
	#endregion
}