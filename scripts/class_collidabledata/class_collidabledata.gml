/// @about
///	A simple container use to return collision data when a collision is detected.
///	The collidable class types and collision-specific data will be stored for
///	access.
///
/// Check each collision shape class for the relevant collision data it can return.
/// Collisions will return the simpler version of the two shapes. For example, 
/// A Ray <-> AABB check will return a CollidableDataRay() with the relevant collision
/// data from the perspective of the Ray, even if the box is the one checking the
/// collision.

/// @param	{Collidable}	type_a
/// @param	{Collidable}	type_b
function CollidableData(type_a=Collidable, type_b=Collidable) constructor {
	#region PROPERTIES
	self.type_a = type_a;
	self.type_b = type_b;
	body_a = undefined;
	body_b = undefined;
	data = {};
	#endregion
	
	#region METHODS
	/// @desc	Returns data about the collision; this data is dependent on the
	///			type of colliding bodies but will always be a struct. Child classes
	///			should have functions that read relevant parts of the data.
	function get_data(){
		return data;
	}
	
	/// @desc	Returns the class type of the instance checking for the collision.
	function get_colliding_class(){
		return type_a;
	}
	
	/// @desc	Returns the class type of the instance the collision is checked against.
	function get_affected_class(){
		return type_b;
	}
	
	/// @desc	Returns the class of the body that isn't the one specified.
	function get_other_class(body){
		if (not is_instanceof(body, Body))
			throw new Exception("invalid type, expected [Body]!");
		
		if (body.get_index() == body_a.get_index())
			return type_b;
		
		return type_a;
	}
	
	/// @desc	Returns the body containing the instance of the collidable checking for the collision.
	function get_colliding_body(){
		return body_a;
	}
	
	/// @desc	Returns the body containing the instance of the collidable being checked against.
	function get_affected_body(){
		return body_b;
	}
	
	/// @desc	Returns the OTHER body that isn't the one specified, whether it is colliding or affected.
	function get_other_body(body){
		if (not is_instanceof(body, Body))
			throw new Exception("invalid type, expected [Body]!");
		
		if (body.get_index() == body_a.get_index())
			return body_b;
		
		return body_a;
	}
	#endregion
}


/// @desc	Base collidable data for 'spatial' objects that have a volume.
function CollidableDataSpatial(body_a, body_b, type_a=Collidable, type_b=Collidable) : CollidableData(type_a, type_b) constructor {
	#region PROPERTIES
	self.body_a = body_a;
	self.body_b = body_b;
	#endregion
	
	#region STATIC METHODS
	/// @desc	Given an array of CollidableDataSpatial instances, combines all the
	///			push vectors applied to the specified body and returns the result.
	static calculate_combined_push_vector = function(body, array){
		var vector = vec();
		for (var i = array_length(array) - 1; i >= 0; --i){
			var data = array[i];
			if (not is_instanceof(data, CollidableDataSpatial))
				continue;
			
			if (U3DObject.are_equal(body, data.get_colliding_body()))
				vector = vec_add_vec(vector, data.get_push_vector());
				
			if (U3DObject.are_equal(body, data.get_affected_body()))
				vector = vec_sub_vec(vector, data.get_push_vector());
		}
		
		return vector;
	}
	
	/// @desc	Given a CollidableDataAAB, creates a copy with all values reversed.
	/// @note	This can create an invalid collidable structure if the affected type's
	///			ancestor is not an AABB.
	static calculate_reverse = function(data){
		if (not is_instanceof(data, CollidableDataSpatial))
			throw new Exception("invalid type, expected [CollidableDataSpatial]!");
			
		var ndata = new CollidableDataSpatial(data.body_b, data.body_a, data.type_b, data.type_a);
		ndata.data.push_vector = vec_reverse(data.data.push_vector);
		ndata.data.push_forward = vec_reverse(data.data.push_forward);
		ndata.data.push_up = vec_reverse(data.data.push_up);
		ndata.data.push_right = vec_reverse(data.data.push_right);
		return ndata;
	}
	#endregion
	
	#region METHODS
	/// @desc	Returns the push vector required to push body_b out
	///			of body_a in the shortest direction. Depending on the collision
	///			type this MAY NOT be axis-aligned!
	function get_push_vector(){
		return data[$ "push_vector"] ?? vec();
	}
	
	/// @desc	Returns the push vector require to push body_b out
	///			of body_a on the global forward axis.
	/// @note	Vector may be negative.
	function get_push_x(){
		return data[$ "push_forward"] ?? vec();
	}
	
	/// @desc	Returns the push vector require to push body_b out
	///			of body_a on the global up axis.
	/// @note	Vector may be negative.
	function get_push_y(){
		return data[$ "push_up"] ?? vec();
	}
	
	/// @desc	Returns the push vector require to push body_b out
	///			of body_a on the global right axis.
	/// @note	Vector may be negative.
	function get_push_z(){
		return data[$ "push_right"] ?? vec();
	}
	#endregion
	
}