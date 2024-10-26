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
	
	/// @desc	Returns a struct containing the appropriate translation, rotation, and scale
	///			given a lerp value within the timeline.
	function build_trs_properties_lerp(lerpvalue){
		lerpvalue = clamp(lerpvalue, 0, 1);
		return {
			position : is_undefined(position_channel) ? AnimationChannelPosition.get_morph_default() : position_channel.get_transformed_lerp(lerpvalue),
			rotation : is_undefined(position_channel) ? AnimationChannelRotation.get_morph_default() : rotation_channel.get_transformed_lerp(lerpvalue),
			scale : is_undefined(position_channel) ? AnimationChannelScale.get_morph_default() : scale_channel.get_transformed_lerp(lerpvalue),
		}
	}
	
	/// @desc	Returns a struct containing the appropriate translation, rotation, and scale
	///			given a time point within the timeline.
	function get_trs_properties_time(time){
		return {
			position : is_undefined(position_channel) ? AnimationChannelPosition.get_morph_default() : position_channel.get_transformed_time(time),
			rotation : is_undefined(rotation_channel) ? AnimationChannelRotation.get_morph_default() : rotation_channel.get_transformed_time(time),
			scale : is_undefined(scale_channel) ? AnimationChannelScale.get_morph_default() : scale_channel.get_transformed_time(time),
		}
	}
	#endregion
}