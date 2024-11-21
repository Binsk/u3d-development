/// @desc	An orthographic eye that views the world in the shape of a box.
/// @param	{Camera}	camera		id of the camera this eye belongs to
/// @param	{real}		znear		nearest point to the eye that can be rendered (in world coords)
/// @param	{real}		zfar		furthest point to the eye that can be rendered (in world coords)
/// @param	{real}		width		width of the box, in world units
/// @param	{real}		height		height of the box, in world units
function EyeOrthographic(camera_id, znear=0.01, zfar=1024, width=1024, height=1024) : Eye(camera_id, znear, zfar) constructor {
	#region PROPERTIES
	self.width = width;
	self.height = height;
	#endregion
	
	#region METHODS
	function set_size(width, height){
		if (self.width == width and self.height == height)
			return;
			
		self.width = width;
		self.height = height;
		self.matrix_projection = undefined;
		self.matrix_inv_projection = undefined;
	}
	
	function get_projection_matrix(){
		if (not is_undefined(self.matrix_projection))
			return self.matrix_projection;
		
		if (is_undefined(camera_id.buffer_width)) // Cannot determine render size
			return matrix_build_identity();
		
		self.matrix_projection = matrix_build_projection_ortho(width, height, znear, zfar);
		
		if (not get_is_directx_pipeline()){
			self.matrix_projection[5] = -self.matrix_projection[5];
			self.matrix_projection[13] = -self.matrix_projection[13];
		}
		
		return self.matrix_projection;
	}
	#endregion

}