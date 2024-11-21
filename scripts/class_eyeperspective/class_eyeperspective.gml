/// @desc A perspective eye that views the world in a cone-shaped view.
/// @param	{Camera}	camera		id of the camera this eye belongs to
/// @param	{real}		znear		nearest point to the eye that can be rendered (in world coords)
/// @param	{real}		zfar		furthest point to the eye that can be rendered (in world coords)
/// @param	{real}		fov			horizontal field-of-view of the cone
function EyePerspective(camera_id, znear=0.01, zfar=1024, fov=45) : Eye(camera_id, znear, zfar) constructor {
	#region PROPERTIES
	self.fov = fov;
	#endregion
	
	#region METHODS
	function set_fov(fov){
		if (self.fov == fov)
			return;
			
		self.matrix_projection = undefined;
		self.matrix_inv_projection = undefined;
		self.fov = fov;
	}
	
	/// @desc	Return / Build the projection matrix for this eye.
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
	#endregion
}