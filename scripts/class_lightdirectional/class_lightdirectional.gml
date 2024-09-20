/// ABOUT
/// A directional light that has an equal effect on all elements in the scene.
/// The light faces down the x-axis by default and can be rotated via a
/// quaternion.

/// @desc	a new directional light that casts light evenly on all elements in
///			the scene. While a position is not necessary for lighting up objects
///			it does become necessary for casting shadows and instance 'culling'.
function LightDirectional(rotation=quat(), position=vec()) : Light() {
	#region PROPERTIES
	#endregion
	
	#region METHODS
	#endregion
	
	#region INIT
	set_position(position);
	set_rotation(rotation);
	#endregion
}