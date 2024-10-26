function AnimationChannelRotation(bone_id) : AnimationChannel(bone_id) constructor {
	#region STATIC METHODS
	/// @desc	Default 'undefined' morph value for this type.
	static get_morph_default = function(){
		return quat();
	}
	#endregion
	
	#region METHODS
	super.register("add_morph");
	function add_morph(time_start, time_end, value, type=ANIMATION_CHANNEL_TRANSFORM.linear){
		if (not is_quat(value))
			throw new Exception("invalid type, expected [quat]!");
		
		super.execute("add_morph", [time_start, time_end, value, type]);
	}
	
	function transform_linear(time, from, to){
		var percent = clamp((time - to.time_start) / (from.time_end - to.time_start), 0, 1);
		return quat_slerp(from.value, to.value, percent);
	}
	#endregion
}