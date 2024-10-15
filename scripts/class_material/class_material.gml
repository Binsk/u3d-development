/// @about
/// A generic material class that is fairly worthless on its own, however it is
/// a common base for all other material types.

function Material() : U3DObject() constructor {
	#region PROPERTIES
	render_keys = {};
	render_stage = CAMERA_RENDER_STAGE.none;
	#endregion
	
	#region METHODS
	/// @desc	Simply returns if this material is the 'missing texture' material
	function get_is_missing_material(){
		return get_index() == U3D.RENDERING.MATERIAL.missing.get_index();
	}
	
	/// @desc	Should apply the necessary shaders, uniforms, and so-forth for
	///			the material. It will be automatically executed by the rendering
	///			system.
	/// @param	{Camera}		camera_id				id of the camera currently rendering the material
	///	@param	{bool}			is_translucent=false	whether or not this is the translucent pass
	function apply(camera_id, is_translucent=false){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Should apply the necessary shaders, uniforms, and so-forth for
	///			the material when performing the shadow-calculation pass. This is generally
	///			just the albedo texture and alpha cutoff.
	function apply_shadow(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Should return the appropriate shader to apply for this material.
	function get_shader(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Some render situations might provide special data and this data
	///			will be provided through a structure of keys. Keys will be set
	///			before ANY other material processing and can be used at any stage
	///			of the rendering pipeline.
	function set_render_keys(keys={}){
		render_keys = keys;
	}
	
	/// @desc	Sets which render stage the material should render in. Usually this
	///			should be opaque whenever possible, translucent if having a partially-
	///			transparent material is absolutely necessary.
	function set_render_stage(stage=CAMERA_RENDER_STAGE.none){
		self.render_stage = clamp(floor(stage), 0, 3);
	}
	#endregion
	
	#region INIT
	#endregion
}