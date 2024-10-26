function AnimationChannelScale(bone_id) : AnimationChannelPosition(bone_id) constructor {
	#region STATIC METHODS
	/// @desc	Default 'undefined' morph value for this type.
	static get_morph_default = function(){
		return vec(1, 1, 1);
	}
	#endregion
}