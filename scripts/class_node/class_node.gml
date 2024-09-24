/// @about
/// Represents a basic 'physical' point in 3D space with a position, rotation,
/// and scale.

/// SIGNALS
///		"set_position"  (from, to)		-	thrown when the position has been modified
///		"set_rotation"  (from, to)		-	thrown when the rotation has been modified
///		"set_scale" 	(from, to)		-	thrown when the scale has been modified

/// @desc	a 3D point in space with a position, rotation, and scale
/// @param	{vec}	 position		a position represented by a vector
/// @param	{quat}	rotation		a rotation represented by a quaternion
/// @param	{scale}   scale		   a scale represented by a vector
function Node(position=vec(), rotation=quat(), scale=vec()) : U3DObject() constructor {
	#region PROPERTIES
	static AXIS_FORWARD = vec(1, 0, 0); // Global axes for convenient access
	static AXIS_UP = vec(0, 1, 0);
	static AXIS_RIGHT = vec(0, 0, 1);
	
	self.position = position;
	self.rotation = rotation;
	self.scale = scale;
	
	matrix_model = undefined;		// 4x4 transform matrix
	matrix_inv_model = undefined;	// 4x4 inverse transform matrix
	#endregion
	
	#region METHODS
	function set_position(position=vec(), relative=false){
		var value_start = self.position;
		if (relative)
			self.position = vec_add_vec(self.position, position);
		else
			self.position = position;
			
		if (vec_equals_vec(value_start, self.position))
			return;
			
		matrix_model = undefined;
		matrix_inv_model = undefined;
		signaler.signal("set_position", [value_start, self.position]);
	}
	
	function set_rotation(rotation=quat(), relative=false){
		var value_start = self.rotation;
		if (relative)
			self.rotation = quat_mul_quat(self.rotation, rotation);
		else
			self.rotation = rotation;
			
		if (quat_equals_quat(value_start, self.rotation))
			return;
			
		matrix_model = undefined;
		matrix_inv_model = undefined;
		signaler.signal("set_rotation", [value_start, self.rotation]);
	}
	
	function set_scale(scale=vec(), relative=false){
		var value_start = self.scale;
		if (relative)
			self.scale = vec_add_vec(self.scale, scale)
		else
			self.scale = scale;
			
		if (vec_equals_vec(value_start, self.scale))
			return;
			
		matrix_model = undefined;
		matrix_inv_model = undefined;
		signaler.signal("set_scale", [value_start, self.scale]);
	}
	
	/// @desc	Rotates the node to face the specified point from its current position.
	///			If relative, the rotation is added to the instance's current rotation.
	///			If NOT relative it is generated from the identity rotation which will
	///			result in a different 'up' and 'right' angle.
	function look_at(position, relative=true){
		var forward_vector = (relative ? get_forward_vector() : Node.AXIS_FORWARD);
		var look = vec_sub_vec(position, self.position);
		if (vec_is_zero(look))	// No need to rotate; same position
			return self.rotation;
		
		var nlook = vec_normalize(look);
		var dot = vec_dot(forward_vector, nlook);
		if (dot >= 1.0){ // Pointing same direction, don't rotate
			if (not relative)
				self.rotation = quat();
				
			return self.rotation;
		}
		var up;
		if (dot <= -1.0){ // Opposite directions, rotate 180 degrees
			if (not relative){
				self.rotation = quat(0, 1, 0, 0); // Rotate 180 degrees on y axis
				return self.rotation;
			}
			
			up = vec_get_perpendicular(forward_vector); // Arbitrary perpendicular vector to rotate around
		}
		else
			up = vec_cross(forward_vector, look); // Vector to rotate around

		var nup = vec_normalize(up);
		var angle = vec_angle_difference(forward_vector, look);
		if (not relative)
			self.rotation = veca_to_quat(vec_to_veca(nup, angle));
		else 
			self.rotation = quat_mul_quat(self.rotation, veca_to_quat(vec_to_veca(nup, angle)));
			
		return self.rotation;
	}
	
	function get_forward_vector(){
		return quat_rotate_vec(rotation, vec(1, 0, 0));
	}
	
	function get_up_vector(){
		return quat_rotate_vec(rotation, vec(0, 1, 0));
	}
	
	function get_right_vector(){
		return quat_rotate_vec(rotation, vec(0, 0, 1));
	}
	
	function get_model_matrix(){
		if (not is_undefined(matrix_model))
			return matrix_model;
/// @stub	build model matrix
	}
	
	function get_inv_model_matrix(){
		if (not is_undefined(matrix_inv_model))
			return matrix_inv_model;
		
/// @stub	build inv model matrix
	}
	#endregion
	
	#region INIT
	#endregion
}