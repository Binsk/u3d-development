/// @about
/// A Ray defines a 3D infinite ray that is defined with a starting point and 
/// orientation.

/// @param	{vec}	orientation			the orientation of the ray
/// @param	{bool}	local_orientation	if true, the orientation is relative to the transform node; otherwise it is global
function Ray(orientation=vec(1, 0, 0), local_orientation=false) : Collidable() constructor {
	#region PROPERTIES
	self.orientation = orientation;
	self.is_local = local_orientation;
	#endregion
	
	#region STATIC METHODS
	static collide_ray = function(ray_a, ray_b, node_a, node_b){
/// @stub	implement 
		return undefined;
	}
	
	static collide_plane = function(ray_a, plane_b, node_a, node_b){
		var plane_normal = node_b.get_data(["collision", "orientation"], vec(0, 1, 0));
		var ray_normal;
		
		if (not ray_a.is_local)
			ray_normal = ray_a.orientation;
		else
			ray_normal = node_a.get_data(["collision", "orientation"], vec(1, 0, 0));
			
		var dot_direction = vec_dot(ray_normal, plane_normal);
		var dot_location = -vec_dot(plane_normal, vec_sub_vec(node_a.position, node_b.position));
		
		if (abs(dot_direction) <= 0.001) // Close to perpendicular
			return undefined;
		
		var is_back = false;
		if (dot_direction > 0) // Determine back-faced collision
			is_back = true;
		
		var d = dot_location / dot_direction;
		if (d < 0) // Pointing away from the plane
			return undefined;
		
		var dx = vec_mul_scalar(ray_normal, d); // Offset from ray start the collision occurs
		var data = new CollidableData(Ray, Plane);
		
		data.data = {
			is_backface : is_back,	// Whether or not the ray is intersecting the backside of the plane
			intersection : vec_add_vec(node_a.position, dx)	// Intersection point in world space
		};
		return data;
	}
	#endregion
	
	#region METHODS
	function transform(node){
		if (not is_local)
			return;
			
		// Calculate rotation relative to the node
		node.set_data(["collision", "orientation"], vec_normalize(matrix_multiply_vec(node.get_model_matrix(), self.orientation)));
	}
	#endregion
}