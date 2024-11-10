/// @about
///	A simple container use to return collision data when a collision is detected.
///	The collidable class types and collision-specific data will be stored for
///	access.
function CollidableData(type_a=Collidable, type_b=Collidable) constructor {
	#region PROPERTIES
	self.type_a = type_a;
	self.type_b = type_b;
	data = {};
	#endregion
	
	#region METHODS
	/// @desc	Returns data about the collision; this data is dependent on the
	///			type of colliding bodies but will always be a struct.
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
	#endregion
}