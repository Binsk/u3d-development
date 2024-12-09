/// @about
///	A sphere collision must be of equal size in all directions. If the parent
///	body is scaled, the smallest scale axis will be used as the scale factor
/// for the entire sphere.

function Sphere(radius) : AABB(vec(radius, radius, radius)) constructor {
	#region STATIC METHODS
	static collide_sphere = function(sphere_a, sphere_b, node_a, node_b){
		var position_a = vec_add_vec(node_a.position, node_a.get_data(["collision", "offset"], vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data(["collision", "offset"], vec()));
		var extends_a = node_a.get_data(["collision", "aabb_extends"], sphere_a.extends);
		var extends_b = node_b.get_data(["collision", "aabb_extends"], sphere_b.extends);
		var radius_a = vec_min_component(extends_a);
		var radius_b = vec_min_component(extends_b);
		
		var distance = vec_magnitude(vec_sub_vec(position_a, position_b));
		if (distance > radius_a + radius_b)	// No collision
			return undefined;
		
		var push_vector = vec_normalize(vec_sub_vec(position_a, position_b));
		push_vector = vec_mul_scalar(push_vector, (radius_a + radius_b) - distance);
		var data = new CollidableDataSphere(node_a, node_b, Sphere);
		data.data.push_vector = push_vector;
		return data;
	}
	
	static collide_aabb = function(sphere_a, aabb_b, node_a, node_b){
		return undefined; /// @stub	Implement!
	}
	#endregion
	
	#region METHODS
	#endregion

	#region INIT
	#endregion
}

function CollidableDataSphere(body_a, body_b, type_b=Collidable) : CollidableData(Sphere, type_b) constructor {
	#region PROPERTIES
	self.body_a = body_a;
	self.body_b = body_b;
	#endregion
	
	#region STATIC METHODS
	/// @desc	Given an array of CollidableDataAABB instances, combines all the
	///			push vectors applied to the specified body and returns the result.
	static calculate_combined_push_vector = function(body, array){
		var vector = vec();
		for (var i = array_length(array) - 1; i >= 0; --i){
			var data = array[i];
		if (not is_instanceof(data, CollidableDataAABB))
				continue;
			
			if (U3DObject.are_equal(body, data.get_colliding_body()))
				vector = vec_add_vec(vector, data.get_push_vector());
				
			if (U3DObject.are_equal(body, data.get_affected_body()))
				vector = vec_sub_vec(vector, data.get_push_vector());
		}
		
		return vector;
	}
	#endregion
	
	#region METHODS
	function get_push_vector(){
		return data.push_vector;
	}
	#endregion
}