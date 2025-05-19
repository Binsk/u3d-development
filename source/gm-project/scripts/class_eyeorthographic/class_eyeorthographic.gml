/// @desc	An orthographic eye that views the world in the shape of a box.
/// @param	{real}		znear		nearest point to the eye that can be rendered (in world coords)
/// @param	{real}		zfar		furthest point to the eye that can be rendered (in world coords)
/// @param	{real}		width		width of the box, in world units
/// @param	{real}		height		height of the box, in world units
function EyeOrthographic(znear=0.01, zfar=1024, width=1024, height=1024) : Eye(znear, zfar) constructor {
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
		self.matrix_p = undefined;
		self.matrix_inv_p = undefined;
	}
	
	function get_projection_matrix(){
		if (not is_undefined(self.matrix_p))
			return self.matrix_p;
		
		self.matrix_p = matrix_build_projection_ortho(width, height, znear, zfar);
		
		if (not get_is_directx_pipeline()){
			self.matrix_p[5] = -self.matrix_p[5];
			self.matrix_p[13] = -self.matrix_p[13];
		}
		
		return self.matrix_p;
	}
	#endregion

}