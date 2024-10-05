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
function Node(position=vec(), rotation=quat(), scale=undefined) : U3DObject() constructor {
	#region PROPERTIES
	static AXIS_FORWARD = vec(1, 0, 0); // Global axes for convenient access
	static AXIS_UP = vec(0, 1, 0);
	static AXIS_RIGHT = vec(0, 0, 1);
	
	self.position = position;
	self.rotation = rotation;
	self.scale = (scale ?? vec(1, 1, 1));
	
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
			self.rotation = quat_mul_quat(rotation, self.rotation);
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
	function look_at(position){
		var forward_vector = Node.AXIS_FORWARD;
		var look = vec_sub_vec(position, self.position);
		if (vec_is_zero(look))	// No need to rotate; same position
			return self.rotation;
		
		var nlook = vec_normalize(look);
		var dot = vec_dot(forward_vector, nlook);
		if (dot >= 1.0){ // Pointing same direction, don't rotate
			set_rotation(quat());
			return self.rotation;
		}
			
		var axis;
		if (dot <= -1.0){ // Opposite directions, rotate 180 degrees
			set_rotation(quat(0, 1, 0, 0)); // Rotate 180 degrees on y axis
			return self.rotation;
		}
		else
			axis = vec_cross(forward_vector, look); // Vector to rotate around

		var naxis = vec_normalize(axis);
		var angle = vec_angle_difference(forward_vector, look);
		set_rotation(veca_to_quat(vec_to_veca(naxis, angle)));
			
		return self.rotation;
	}
	
	/// @desc	The same as look_at but attempts to keep the up vector as close to the
	///			specified up vector as possible
	function look_at_up(position, up=Node.AXIS_UP){
		look_at(position); // Perform regular look_at
		
		// Add another rotation to point 'up'
		var up_vector = get_up_vector();
		var forward_vector = get_forward_vector();
		var left = vec_cross(up, forward_vector);
		var target_vector = vec_normalize(vec_cross(forward_vector, left));
		
		var dot = vec_dot(target_vector, up_vector);
		if (dot >= 1.0) // Pointing same direction, don't rotate
			return self.rotation;
			
		var angle = vec_angle_difference(up_vector, target_vector);
		
			// Invert the rotation angle if the axis is backwards
		if (dot > -1.0 and vec_dot(forward_vector, vec_cross(up_vector, target_vector)) < 0)
			angle = -angle;
		
		set_rotation(veca_to_quat(vec_to_veca(forward_vector, angle)), true);
			
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
			
		matrix_model = matrix_multiply_post(
			matrix_build_scale(scale.x, scale.y, scale.z),						// S
			matrix_build_quat(rotation.x, rotation.y, rotation.z, rotation.w),	// R
			matrix_build_translation(position.x, position.y, position.z)		// T
		);
		return matrix_model;
	}
	
	function get_inv_model_matrix(){
		if (not is_undefined(matrix_inv_model))
			return matrix_inv_model;
		
		matrix_inv_model = matrix_get_inverse(get_model_matrix());
		return matrix_inv_model;
	}
	#endregion
	
	#region INIT
	#endregion
}