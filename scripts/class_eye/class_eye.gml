/// @about
///	An Eye represents an actual projection in 3D space and must be attached
/// to a Camera() in order to render anything. The Eye will have a projection
/// matrix and a view matrix that is relative to the camera's position.

/// Eye() instances are generally auto-generated and cleaned up by the Camera()
/// instance and do not need to be managed manually unless you are designing a
/// custom type of Camera() class.

function Eye(camera_id, znear=0.01, zfar=1024, fov=45) : U3DObject() constructor {
	#region PROPERTIES
	self.camera_id = camera_id;		// The camera we belong to
	self.znear = znear;
	self.zfar = zfar;
	self.fov = fov;
	
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
	
	function set_fow(fow){
		self.matrix_projection = undefined;
		self.matrix_inv_projection = undefined;
		self.fow = fow;
	}
	
	/// @desc	Sets the local eye matrix, relative to the camera. If set to undefined
	///			the system will optimize-out the matrix calculation which equates to
	///			the identity matrix.
	function set_eye_matrix(matrix=undefined){
		self.matrix_eye = matrix;
		self.matrix_view = undefined;
		self.matrix_inv_view = undefined;
	}
	
	function get_camera(){
		return camera_id;
	}
	
	/// @desc	Build the view matrix required for this camera.
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
	
	function get_inverse_view_matrix(){
		if (not is_undefined(matrix_inv_view))
			return matrix_inv_view;
		
		matrix_inv_view = matrix_get_inverse(get_view_matrix());;
		return matrix_inv_view;
	}
	
	/// @desc	Build the projection matrix required for this camera.
	function get_projection_matrix(){
		if (not is_undefined(self.matrix_projection))
			return self.matrix_projection;
		
		if (is_undefined(camera_id.buffer_width)) // Cannot determine render size
			return matrix_build_identity();

		var aspect = camera_id.buffer_width / camera_id.buffer_height;
		var yfov = 2.0 * arctan(dtan(fov/2) * aspect);
		
		var h = 1 / tan(yfov * 0.5);
		var w = h / aspect;
		var a = zfar / (zfar - znear);
		var b = (-znear * zfar) / (zfar - znear);
		var matrix = [
			w, 0, 0, 0,
			0, get_is_directx_pipeline() ? h : -h, 0, 0,
			0, 0, a, 1,
			0, 0, b, 0
		];
		
		self.matrix_projection = matrix;
		return matrix;
	}
	
	function get_inverse_projection_matrix(){
		if (not is_undefined(matrix_inv_projection))
			return matrix_inv_projection;
		
		matrix_inv_projection = matrix_get_inverse(get_projection_matrix());
		return matrix_inv_projection;
	}
	#endregion
	
	#region INIT
	if (not is_instanceof(camera_id, Camera))
		throw new Exception("invalid type, expected [Camera]!");
	
	// Attach to the camera; if it moves / rotates we reset our cached matrices:
	var reset_matrix = new Callable(self, function(){self.matrix_view = undefined; self.matrix_inv_view = undefined;});
	camera_id.signaler.add_signal("set_rotation", reset_matrix);
	camera_id.signaler.add_signal("set_position", reset_matrix);
	#endregion
}