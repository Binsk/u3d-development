/// @about
/// An animation channel defines a single bone's transforms over an animation 
/// for a single property. A bone may have multple animation channels assigned
/// to it with mixed time-stamps. The following class is a template and doesn't
/// define a specific supported type. A child-class should be used instead.

enum ANIMATION_CHANNEL_TRANSFORM {
	step,
	linear,		// lerp or slerp
	cubicspline	// Not supported ATM
}

function AnimationChannel(bone_id) : U3DObject() constructor {
	#region PROPERTIES
	self.bone_id = bone_id;
	morph_array = [];
	morph_length = 0;	// Length of the channel, in time units
	morph_definition = ds_priority_create();
	#endregion
	
	#region METHODS
	/// @desc	Returns the morphed value at a specific lerp value between
	///			[0..1] of the entire animation track.
	function get_transformed_lerp(lerpvalue){
		lerpvalue = clamp(lerpvalue, 0, 1);
		return get_transformed_time(morph_length * lerpvalue);
	}
	
	/// @desc	Returns the morphed value at the specific time value between
	///			[0..MAX_TIME] of the animation track.
	function get_trasformed_time(time){
		var array = get_morphs_at_time(time);
		
		if (array_length(array) <= 1)
			return array[0];
		
		if (array[0].type == ANIMATION_CHANNEL_TRANSFORM.step)
			return transform_step(time, array[0], array[1]);
		else if (array[0].type == ANIMATION_CHANNEL_TRANSFORM.linear)
			return transform_linear(time, array[0], array[1]);
		
		throw new Exception($"invalid/unsupported channel transform type [{array[0].type}]");
	}
	
	/// @desc	Returns the array of morphs interlapping with the specified lerp
	///			percentage between [0..1].
	function get_morphs_at_lerp(lerpvalue){
		lerpvalue = clamp(lerpvalue, 0, 1);
		return get_morphs_at_time(morph_length * lerpvalue);
	}
	
	/// @desc	Returns and array of morphs interlapping with the specific time.
	function get_morphs_at_time(time){
		var array = [];
		var morph_count = array_length(morph_array);
		var lerp_count = 0;
		for (var i = 0; i < morph_count; ++i){
			var morph = morph_array[i];
			if (morph.time_start <= time and (morph.time_end >= time or i == morph_count - 1)){
				++lerp_count;
				array_push(array, morph);
				
				if (lerp_count >= 2)
					break;
			}
			
			if (morph.time_end < time)
				break;
		}
		
		if (array_length(array) <= 0)
			return [get_morph_default()];
		
		return array;
	}
	
	/// @desc	Default 'undefined' morph value for this type.
	function get_morph_default(){
		return undefined;
	}
	
	function get_bone_index(){
		return bone_id;
	}
	
	/// @desc	Adds a morph value to the definition; can only be done if the
	///			channel is not frozen.
	function add_morph(time_start, time_end, value, type=ANIMATION_CHANNEL_TRANSFORM.linear){
		if (is_undefined(morph_definition))
			throw new Exception("failed to add morph, animation channel is frozen.");
			
		ds_priority_add(morph_definition, {
			time_start, time_end, value, type
		}, time_start);
	}
	
	function transform_step(time, from, to){
		if (time >= from.time_end)
			return to.value;
		
		return from.value;
	}
	
	function transform_linear(time, from, to){
		return get_morph_default();
	}
	
	/// @desc	Freezes the definition
	function freeze(){
		if (is_undefined(morph_definition)) // Already frozen
			return;
		
		morph_array = array_create(ds_priority_size(morph_definition));
		for (var i = 0; not ds_priority_empty(morph_definition); ++i){
			var data = ds_priority_delete_min(morph_definition);
			morph_length = max(morph_length, data.time_end);
			morph_array[i] = data;
		}
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		if (not is_undefined(morph_definition))
			ds_priority_destroy(morph_definition);
		
		morph_definition = undefined;
	}
	#endregion
}