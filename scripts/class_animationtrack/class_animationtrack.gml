/// @about
/// An AnimationTrack() contains a series of AnimationPose() instances as well
///	as time stamps for each pose. An AnimationTrack is responsible for calculating
/// skeletal morphs over time for a single animation.
function AnimationTrack(name) : U3DObject() constructor {
	#region PROPERTIES
	self.name = name;
	channel_data = {};	// bone_id -> animation channel group
	#endregion
	
	#region METHODS
	function get_name(){
		return name;
	}
	
	function get_bone_count(){
		return struct_names_count(channel_data);
	}
	
	function get_channel_count(){
		var count = 0;
		var names = struct_get_names(channel_data);
		for (var i = array_length(names) - 1; i >= 0; --i)
			count += channel_data[$ names[i]].get_channel_count();
		
		return count;
	}
	
	function add_channel_group(group){
		if (not is_instanceof(group, AnimationChannelGroup)){
			Exception.throw_conditional("invalid type, expected [AnimationChannelGroup]!");
			return;
		}
		
		replace_child_ref(group, channel_data[$ group.get_bone_index()]);
		channel_data[$ group.get_bone_index()] = group;
	}
	#endregion
}