/// @about
/// Defines an inifinite plane in 3D space.

/// @param	{vec}	normal		face normal defining plane orientation
function Plane(normal=vec(0, 1, 0)) : Collidable() constructor {
	#region PROPERTIES
	self.normal = normal;
	#endregion
	
	#region METHODS
	
	static collide_ray = function(plane_a, ray_b, node_a, node_b){
		return Ray.collide_plane(ray_b, plane_a, node_b, node_a);
	}
	
	static collide_plane = function(plane_a, plane_b, node_a, node_b){
/// @stub	Implement; namely the infinite line of intersection
		return undefined;
	}
	
	function transform(node){
		// Calculate rotation relative to the node
		node.set_data(["collision", "orientation"], vec_normalize(matrix_multiply_vec(node.get_model_matrix(), self.normal)));
	}
	#endregion
}