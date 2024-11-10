/// @about
/// Defines an inifinite plane in 3D space.

/// @param	{vec}	normal		face normal defining plane orientation
function Plane(normal=vec(0, 1, 0)) : Collidable() constructor {
	#region PROPERTIES
	self.normal = normal;
	#endregion
	
	#region METHODS
	function transform(node){
		// Calculate rotation relative to the node
		node.set_data(["collision", "orientation"], vec_normalize(matrix_multiply_vec(node.get_model_matrix(), self.normal)));
	}
	#endregion
}