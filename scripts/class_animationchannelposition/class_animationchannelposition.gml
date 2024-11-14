function AnimationChannelPosition() : AnimationChannel() constructor {
	
	#region STATIC METHODS
	/// @desc	Default 'undefined' morph value for this type.
	static get_morph_default = function(){
		return vec();
	}
	#endregion
	
	#region METHODS
	super.register("add_morph");
	/// @desc	Adds a morph value to the definition; can only be done if the
	///			channel is not frozen.
	/// @param	{real}	time_stamp	the time at which this morph is applied (in seconds)
	/// @param	{vec}	value		the morph value to apply
	/// @param	{ANIMATION_CHANNEL_TRANSFORM}	type	morph method to use
	function add_morph(time_start, value, type=ANIMATION_CHANNEL_TRANSFORM.linear){
		if (not is_vec(value))
			throw new Exception("invalid type, expected [vec]!");
		
		super.execute("add_morph", [time_start, value, type]);
	}
	
	/// @desc	Execute the 'interpolated' morph method.
	/// @param	{real}	time	current time in the channel
	/// @param	{vec}	from	morph we are transforming from
	/// @param	{vec}	to		morph we are transforming to
	function transform_linear(time, from, to){
		var percent = 1.0;
		if (to.time_stamp != from.time_stamp)
			percent = clamp((time - from.time_stamp) / (to.time_stamp - from.time_stamp), 0, 1);
			
		return vec_lerp(from.value, to.value, percent);
	}
	#endregion
}