/// @desc A perspective eye that views the world in a cone-shaped view.
/// @param	{real}		znear		nearest point to the eye that can be rendered (in world coords)
/// @param	{real}		zfar		furthest point to the eye that can be rendered (in world coords)
/// @param	{real}		yfov			vertical field-of-view of the cone (horizontal auto-calculated)
function EyePerspective(znear=0.01, zfar=1024, y_fov=pi/2.5, aspect=1.0) : Eye(znear, zfar) constructor {
	#region PROPERTIES
	self.fov = y_fov;
	self.aspect = 1.0;
	#endregion
	
	#region METHODS
	/// @desc	Sets the FOV of the camera on the y-axis.
	/// @param	{real}	yfov	field-of-view in radians
	function set_yfov(fov){
		if (self.fov == fov)
			return;
			
		self.matrix_p = undefined;
		self.matrix_inv_p = undefined;
		self.fov = fov;
	}
	
	/// @desc	Calculates the y-fov based on the specified x-fov.
	///	@note	x-fov changes with aspect ratio changes.
	/// @param	{real}	xfov	field-of-view in radians
	function set_xfov(fov, aspect=1.0){
		self.fov = 2.0 * arctan(tan(fov * 0.5) * aspect);
	}
	
	function set_aspect_ratio(aspect){
		self.aspect = aspect;
	}
	
	/// @desc	Return / Build the projection matrix for this eye.
	function get_projection_matrix(){
		if (not is_undefined(self.matrix_p))
			return self.matrix_p;
		
		var h = 1 / tan(fov * 0.5);
		var w = h / aspect;
		var a = zfar / (zfar - znear);
		var b = (-znear * zfar) / (zfar - znear);
		var matrix = [
			w, 0, 0, 0,
			0, get_is_directx_pipeline() ? h : -h, 0, 0,
			0, 0, a, 1,
			0, 0, b, 0
		];
		
		self.matrix_p = matrix;
		return matrix;
	}
	#endregion
}