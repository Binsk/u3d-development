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
	
	/// @desc	Returns the body containing the instance of the collidable checking for the collision.
	function get_colliding_body(){
		return body_a;
	}
	
	/// @desc	Returns the body containing the instance of the collidable being checked against.
	function get_affected_body(){
		return body_b;
	}
	#endregion
}


