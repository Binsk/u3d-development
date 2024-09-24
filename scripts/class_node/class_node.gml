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
	
	/// @desc	rotates the node to face the specified point from its current position.
	function look_at(position, up=Node.AXIS_UP){
		var look = vec_sub_vec(position, self.position);
		var nlook = vec_normalize(look);
		if (vec_equals_vec(nlook, up)){
			Exception.throw_conditional("Cannot calculate up vector!");
			return vec();
		}
		
		var right = vec_cross(look, up);
		var nup = vec_normalize(vec_cross(right, nlook)); // Adjusted up vector
/// @stub	Set rotation from these values
	}
	
	function get_forward_vector(){
		return quat_rotate_vec(rotation, vec3(1, 0, 0));
	}
	
	function get_up_vector(){
		return quat_rotate_vec(rotation, vec3(0, 1, 0));
	}
	
	function get_right_vector(){
		return quat_rotate_vec(rotation, vec3(0, 0, 1));
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