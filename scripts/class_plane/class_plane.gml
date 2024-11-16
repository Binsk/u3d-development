/// @about
/// Defines an inifinite plane in 3D space where the normal specified is the 
/// facing direction of the plane.

/// @param	{vec}	normal		face normal defining plane orientation
function Plane(normal=vec(0, 1, 0)) : Collidable() constructor {
	#region PROPERTIES
	self.normal = normal;
	#endregion
	
	#region METHODS
	
	/// @desc	Returns the collision info between the plane and a ray.
	/// @param	{Plane}	plane
	/// @param	{Ray}	ray
	/// @param	{Node}	node_a		node defining spatial information for plane
	/// @param	{Node}	node_b		node defining spatial information for ray
	static collide_ray = function(plane_a, ray_b, node_a, node_b){
		return Ray.collide_plane(ray_b, plane_a, node_b, node_a);
	}
	
	/// @desc	Returns the collision info between the plane and another plane
	/// @param	{Plane}	plane_a
	/// @param	{Plane}	plane_b
	/// @param	{Node}	node_a		node defining spatial information for plane_a
	/// @param	{Node}	node_b		node defining spatial information for plane_b
	static collide_plane = function(plane_a, plane_b, node_a, node_b){
/// @stub	Implement; namely the infinite line of intersection
		return undefined;
	}
	
	function transform(node){
		if (not super.execute("transform", [node]))
			return false;
			
		// Calculate rotation relative to the node
		if (node.get_data("collision.static", false))
			node.set_data(["collision", "orientation"], self.normal);
		else
			node.set_data(["collision", "orientation"], vec_normalize(matrix_multiply_vec(node.get_model_matrix(), self.normal)));
		return true;
	}
	#endregion
}