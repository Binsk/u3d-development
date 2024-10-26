/// @desc	Contains a group of channels for a specific bone ID. Grouping bone
///			channels together simplifies generating transformation matrices.
function AnimationChannelGroup(bone_id) : U3DObject() constructor {
	#region PROPERTIES
	self.bone_id = bone_id;
	position_channel = undefined;
	rotation_channel = undefined;
	scale_channel = undefined;
	#endregion
	
	#region METHODS
	function set_position_channel(channel=undefined){
		if (not is_instanceof(channel, AnimationChannelPosition) and not is_undefined(channel))
			throw new Exception("invalid type, expected [AnimationChannelPosition]!");
		
		replace_child_ref(channel, position_channel);
		position_channel = channel;
	}
	
	function set_rotation_channel(channel=undefined){
		if (not is_instanceof(channel, AnimationChannelRotation) and not is_undefined(channel))
			throw new Exception("invalid type, expected [AnimationChannelPosition]!");
		
		replace_child_ref(channel, rotation_channel);
		rotation_channel = channel;
	}
	
	function set_scale_channel(channel=undefined){
		if (not is_instanceof(channel, AnimationChannelScale) and not is_undefined(channel))
			throw new Exception("invalid type, expected [AnimationChannelScale]!");
		
		replace_child_ref(channel, scale_channel);
		scale_channel = channel;
	}
	
	function set_channel(channel){
		if (is_instanceof(channel, AnimationChannelScale))
			set_scale_channel(channel);
		else if (is_instanceof(channel, AnimationChannelRotation))
			set_rotation_channel(channel);
		else if (is_instanceof(channel, AnimationChannelPosition))
			set_position_channel(channel);
		else if (is_instanceof(channel, AnimationChannel))
			throw new Exception("failed to set channel, [AnimationChannel] is a template class!");
		else
			throw new Exception("invalid type, expected [AnimationChannel]!");
	}
	
	function get_bone_index(){
		return bone_id;
	}
	
	function get_channel_count(){
		var count = 0;
		count += not is_undefined(position_channel);
		count += not is_undefined(rotation_channel);
		count += not is_undefined(scale_channel);
		return count;
	}
	#endregion
}