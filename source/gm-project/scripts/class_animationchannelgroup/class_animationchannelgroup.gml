/// @desc	Contains a group of the three primary channel types and handles
///			interpolating them together as well as interpolating defaults if
///			a channel is undefined. There should generally be one channel group
///			per bone per animation track.
///
/// @note	Channel groups are assigned a bone index once they are attached to
///			an animation track; thus they can be re-used across animations or
///			even separate skeletons.
function AnimationChannelGroup() : U3DObject() constructor {
	#region PROPERTIES
	position_channel = undefined;
	rotation_channel = undefined;
	scale_channel = undefined;
	#endregion
	
	#region METHODS
	/// @desc	Sets the channel to use for the positional transforms.
	/// @param	{AnimationChannelPosition}	channel
	function set_position_channel(channel=undefined){
		if (not is_instanceof(channel, AnimationChannelPosition) and not is_undefined(channel))
			throw new Exception("invalid type, expected [AnimationChannelPosition]!");
		
		self.replace_child_ref(channel, position_channel);
		position_channel = channel;
	}
	
	/// @desc	Sets the channel to use for the rotational transforms.
	/// @param	{AnimationChannelRotation}	channel
	function set_rotation_channel(channel=undefined){
		if (not is_instanceof(channel, AnimationChannelRotation) and not is_undefined(channel))
			throw new Exception("invalid type, expected [AnimationChannelPosition]!");
		
		self.replace_child_ref(channel, rotation_channel);
		rotation_channel = channel;
	}
	
	/// @desc	Sets the channel to use for the scalar transforms.
	/// @param	{AnimationChannelScale}	channel
	function set_scale_channel(channel=undefined){
		if (not is_instanceof(channel, AnimationChannelScale) and not is_undefined(channel))
			throw new Exception("invalid type, expected [AnimationChannelScale]!");
		
		self.replace_child_ref(channel, scale_channel);
		scale_channel = channel;
	}
	
	/// @desc	Assigns a channel to this group. Automatically sorts 
	/// 		the channel type and assigns accordingly.
	/// @param	{AnimationChannel}	channel
	function set_channel(channel){
		if (is_instanceof(channel, AnimationChannelScale))
			self.set_scale_channel(channel);
		else if (is_instanceof(channel, AnimationChannelRotation))
			self.set_rotation_channel(channel);
		else if (is_instanceof(channel, AnimationChannelPosition))
			self.set_position_channel(channel);
		else if (is_instanceof(channel, AnimationChannel))
			throw new Exception("failed to set channel, [AnimationChannel] is a template class!");
		else
			throw new Exception("invalid type, expected [AnimationChannel]!");
	}
	
	/// @desc	Returns the number of channels currently defined for this group.
	function get_channel_count(){
		var count = 0;
		count += not is_undefined(position_channel);
		count += not is_undefined(rotation_channel);
		count += not is_undefined(scale_channel);
		return count;
	}
	
	/// @desc	Retruns the largest time-stamp across all attached channels.
	function get_channel_length(){
		return max(
			is_undefined(position_channel) ? 0 : position_channel.get_morph_length(),
			is_undefined(rotation_channel) ? 0 : rotation_channel.get_morph_length(),
			is_undefined(scale_channel) ? 0 : scale_channel.get_morph_length()
		);
	}
	
	/// @desc	Returns a struct containing the appropriate translation, rotation, and scale
	///			given a lerp value within the timeline.
	function get_trs_properties_lerp(lerpvalue){
		lerpvalue = clamp(lerpvalue, 0, 1);
		return {
			position : is_undefined(position_channel) ? AnimationChannelPosition.get_morph_default() : position_channel.get_transformed_lerp(lerpvalue),
			rotation : is_undefined(rotation_channel) ? AnimationChannelRotation.get_morph_default() : rotation_channel.get_transformed_lerp(lerpvalue),
			scale : is_undefined(scale_channel) ? AnimationChannelScale.get_morph_default() : scale_channel.get_transformed_lerp(lerpvalue),
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