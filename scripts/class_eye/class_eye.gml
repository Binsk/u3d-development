/// @about
///	An Eye represents an actual projection in 3D space and must be attached
/// to a Camera() in order to render anything. The Eye will have a projection
/// matrix and a view matrix that is relative to the camera's position.

/// Eye() instances are generally auto-generated and cleaned up by the Camera()
/// instance and do not need to be managed manually unless you are designing a
/// custom type of Camera() class.

/// @param	{real}		znear		nearest point to the eye that can be rendered (in world coords)
/// @param	{real}		zfar		furthest point to the eye that can be rendered (in world coords)
function Eye(znear=0.01, zfar=1024) : U3DObject() constructor {
	#region PROPERTIES
	static ACTIVE_INSTANCE = undefined;
	self.camera_id = undefined;		// The camera we belong to (can also be a regular node)
	self.znear = znear;
	self.zfar = zfar;

	self.matrix_eye = undefined;	// Relative to the camera; if undefined treated is identity (and saves a matrix op)
	self.matrix_projection = undefined;
	self.matrix_inv_projection = undefined;

	self.matrix_view = undefined; // Combined w/ camera's matrices
	self.matrix_inv_view = undefined;
	#endregion
	
	#region METHODS
	function set_znear(znear){
		self.matrix_projection = undefined;
		self.matrix_inv_projection = undefined;
		self.znear = znear;
	}
	
	function set_zfar(zfar){
		self.matrix_projection = undefined;
		self.matrix_inv_projection = undefined;
		self.zfar = zfar;
	}
	
	/// @desc	Sets the local eye matrix, relative to the camera. If set to undefined
	///			the system will optimize-out the matrix calculation which equates to
	///			the identity matrix.
	function set_eye_matrix(matrix=undefined){
		self.matrix_eye = matrix;
		self.matrix_view = undefined;
		self.matrix_inv_view = undefined;
	}
	
	/// @desc	Sets the parent node over this eye; the eye requires a parent in order
	///			to make a number of calculations.
	/// @param	{Node}	node
	function set_camera_node(node){
		if (not is_instanceof(node, Node) and not is_undefined(node)){
			Exception.throw_conditional("invalid type, expected [Node]!");
			return;
		}
		
		if (not is_undefined(camera_id) and not U3DObject.are_equal(node, camera_id)){
			camera_id.signaler.remove_signal("set_rotation", new Callable(self, clear_matrices));
			camera_id.signaler.remove_signal("set_position", new Callable(self, clear_matrices));
		}
		
		camera_id = node;
		
		// Attach to the camera; if it moves / rotates we reset our cached matrices:
		if (not is_undefined(camera_id)){
			camera_id.signaler.add_signal("set_rotation", new Callable(self, clear_matrices));
			camera_id.signaler.add_signal("set_position", new Callable(self, clear_matrices));
		}
	}
	
	/// @desc	Return the camera instance the eye belongs to.
	function get_camera(){
		return camera_id;
	}
	
	function get_znear(){
		return self.znear;
	}
	
	function get_zfar(){
		return self.zfar;
	}
	
	/// @desc	Return / Build the view matrix for this eye.
	function get_view_matrix(){
		if (not is_undefined(self.matrix_view))
			return self.matrix_view;
		
		var forward = camera_id.get_forward_vector();
		var up = camera_id.get_up_vector();
		var to = vec_add_vec(camera_id.position, forward);
		self.matrix_view = matrix_build_lookat(camera_id.position.x, camera_id.position.y, camera_id.position.z, to.x, to.y, to.z, up.x, up.y, up.z);
		
		if (not is_undefined(self.matrix_eye))
			self.matrix_view = matrix_multiply(self.matrix_eye, self.matrix_view);
		
		return self.matrix_view;
	}
	
	/// @desc	Return / Build the inverse of the view matrix for this eye.
	function get_inverse_view_matrix(){
		if (not is_undefined(matrix_inv_view))
			return matrix_inv_view;
		
		matrix_inv_view = matrix_inverse(get_view_matrix());;
		return matrix_inv_view;
	}
	
	
	function get_projection_matrix(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Return / Build the inverse projection matrix for this eye.
	function get_inverse_projection_matrix(){
		if (not is_undefined(matrix_inv_projection))
			return matrix_inv_projection;
		
		matrix_inv_projection = matrix_inverse(get_projection_matrix());
		return matrix_inv_projection;
	}
	
	function clear_matrices(){
		self.matrix_view = undefined;
		self.matrix_inv_view = undefined;
	}
	
	function apply(){
		matrix_set(matrix_view, get_view_matrix());
		matrix_set(matrix_projection, get_projection_matrix());
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		delete anchor;
		anchor = undefined;
	}
	#endregion
}