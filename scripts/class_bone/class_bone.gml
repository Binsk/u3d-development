/// @about
///	A bone represents a 3D transform relative to its parent or, if the bone is
/// root, relative to the model space of the model it applies to.
/// Bones do not have any knowledge of other bones and are simple data containers.

function Bone(index=0, position=vec(), rotation=quat(), scale=vec()) constructor {
	#region PROPERTIES
	self.index = index;		// Bone index in the animation / skeleton
	self.position = position;	// Positional offset relative to the parent
	self.rotation = rotation;	// Rotational offset relative to the parent (the most frequent usage in animation)
	self.scale = scale;			// Scalar offset relative to the parent
	#endregion
}