/// @about
/// Represents a basic 'physical' point in 3D space with a position, rotation,
/// and scale.

/// @signals
///		"set_position"  (from, to)		-	thrown when the position has been modified
///		"set_rotation"  (from, to)		-	thrown when the rotation has been modified
///		"set_scale" 	(from, to)		-	thrown when the scale has been modified
///		"collision_data_updated" ()		-	thrown when collision data has been updated by its collision shape

/// @desc	a 3D point in space with a position, rotation, and scale
/// @param	{vec}	position		a position represented by a vector
/// @param	{quat}	rotation		a rotation represented by a quaternion
/// @param	{vec}	scale			a scale represented by a vector
function Node(position=vec(), rotation=quat(), scale=vec(1, 1, 1)) : U3DObject() constructor {
	#region PROPERTIES
	static AXIS_FORWARD = vec(1, 0, 0); // Global axes for convenient access
	static AXIS_UP = vec(0, 1, 0);
	static AXIS_RIGHT = vec(0, 0, 1);
	
	self.position = position;
	self.rotation = rotation;
	self.scale = scale;
	
	matrix_model = undefined;		// 4x4 transform matrix
	matrix_inv_model = undefined;	// 4x4 inverse transform matrix
	forward_vector = undefined;
	up_vector = undefined;
	right_vector = undefined;
	
	render_layer_bits = int64(-1);		// Which layers we render on (by default, all layers)
	collidable_scan_bits = int64(-1);	// Which layers we look at for collisions
	collidable_mask_bits = int64(-1);	// Which layers we occupy for collisions
	#endregion
	
	#region METHODS
	/// @desc	Sets the current position of the node in world space.
	/// @param	{vec}	position
	/// @param	{bool}	relative	if true, the specified position will be relative to the current position
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
	
	/// @desc	Sets the current rotation of the node in world space. All nodes are
	///			assumed to 'point' down the +X axis by default and the specified 
	///			quaternion rotates relative to that.
	/// @param	{quat}	rotation
	/// @param	{bool}	relative	if set, the rotation quaternion will be multiplied against the current rotation.
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
		forward_vector = undefined;
		up_vector = undefined;
		right_vector = undefined;
		signaler.signal("set_rotation", [value_start, self.rotation]);
	}
	
	/// @desc	Sets the scale of the node in world space.
	/// @param	{vec}	scale
	/// @param	{bool}	relative	if set, the specified scale will be added to the current scale.
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
	
	/// @desc	Sets which render layers this instance appears on. This is a bitwised value
	///			where each bit represents a layer index.
	function set_render_layers(bits){
		render_layer_bits = bits;
	}
	
	/// @desc	Returns a copy of the position vector.
	/// @note	It is faster to simply access the position value, however it must ALWAYS
	///			be treated as constant in that case.
	function get_position(){
		return vec_duplicate(position);
	}

	/// @desc	Returns a copy of the rotation quaternion.
	/// @note	It is faster to simply access the rotation value, however it must ALWAYS
	///			be treated as constant in that case.
	function get_rotation(){
		return quat_duplicate(rotation);
	}
	
	/// @desc	Returns a copy of the scale vector.
	/// @note	It is faster to simply access the scale value, however it must ALWAYS
	///			be treated as constant in that case.
	function get_scale(){
		return vec_duplicate(scale);
	}
	
	/// @desc	Adds this instance to the specified render layer(s)
	function add_render_layers(bits){
		render_layer_bits |= bits;
	}
	
	/// @desc	Removes this instance from the specified layer(s)
	function remove_render_layers(bits){
		render_layer_bits &= ~bits;
	}
	
	/// @desc	Rotates the node to face the specified point from its current position.
	/// 		This does not consider the UP vector so the rotation may cause leaning.
	/// @param	{vec}	position	the position to rotate towards
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
	///			specified up vector as possible while remaining perpendicular to the forward
	/// 		vector.
	/// @param	{vec}	position	the position to rotate towards
	/// @param	{vec}	up			the vector to treat as the local up value
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
	
/// @todo (?) might be worth caching these like w/ the matrices? Quat OPs are not fast.
	/// @desc	Returns the current facing vector in world space.
	function get_forward_vector(){
		forward_vector ??= quat_rotate_vec(rotation, vec(1, 0, 0));
		return forward_vector;
	}
	
	/// @desc	Returns the current up vector in world space.
	function get_up_vector(){
		up_vector ??= quat_rotate_vec(rotation, vec(0, 1, 0));
		return up_vector;
	}
	
	/// @desc	Returns the current right vector in world space.
	function get_right_vector(){
		right_vector ??= quat_rotate_vec(rotation, vec(0, 0, 1));
		return right_vector;
	}
	
	/// @desc	Returns the current model matrix.
	/// @param	{bool}	force_update	if true, forces a recalculation regardless of the cache
	function get_model_matrix(force_update=false){
		if (not is_undefined(matrix_model) and not force_update)
			return matrix_model;
			
		matrix_model = matrix_multiply_post(
			matrix_build_translation(position),		// T
			matrix_build_quat(rotation),			// R
			matrix_build_scale(scale)				// S
		);
		return matrix_model;
	}
	
	/// @desc	Retruns the current inverse of the model matrix.
	/// @param	{bool}	force_update	if true, forces a recalculation regardless of the cache
	function get_inv_model_matrix(force_update=false){
		if (not is_undefined(matrix_inv_model) and not force_update)
			return matrix_inv_model;
		
		matrix_inv_model = matrix_inverse(get_model_matrix());
		return matrix_inv_model;
	}

	/// @desc	Returns the bitwised value of all layers we render on.
	function get_render_layers(){
		return render_layer_bits;
	}
	
	/// @desc	Collision shapes store data in their calling node to help cache
	///			calculations. This wipse the data to be re-calculated next collision check.
	function clear_collision_data(){
		set_data("collision", undefined);
	}
	
	function has_collision_data(){
		return not is_undefined((get_data("collision", undefined)));
	}
	#endregion
	
	#region INIT
	signaler.add_signal("set_position", new Callable(self, clear_collision_data));
	signaler.add_signal("set_scale", new Callable(self, clear_collision_data));
	signaler.add_signal("set_rotation", new Callable(self, clear_collision_data));
	#endregion
}