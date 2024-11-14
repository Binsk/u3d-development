/// @about
/// The scalar channel is identical to the positional channel with the one exception
/// being the morph default.

function AnimationChannelScale() : AnimationChannelPosition() constructor {
	#region STATIC METHODS
	/// @desc	Default 'undefined' morph value for this type.
	static get_morph_default = function(){
		return vec(1, 1, 1);
	}
	#endregion
}