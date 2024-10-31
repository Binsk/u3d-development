function AnimationChannelPosition(bone_id) : AnimationChannel(bone_id) constructor {
	
	#region STATIC METHODS
	/// @desc	Default 'undefined' morph value for this type.
	static get_morph_default = function(){
		return vec();
	}
	#endregion
	
	#region METHODS
	super.register("add_morph");
	function add_morph(time_start, value, type=ANIMATION_CHANNEL_TRANSFORM.linear){
		if (not is_vec(value))
			throw new Exception("invalid type, expected [vec]!");
		
		super.execute("add_morph", [time_start, value, type]);
	}
	
	function transform_linear(time, from, to){
		var percent = 1.0;
		if (to.time_stamp != from.time_stamp)
			percent = clamp((time - from.time_stamp) / (to.time_stamp - from.time_stamp), 0, 1);
			
		return vec_lerp(from.value, to.value, percent);
	}
	#endregion
}