/// @about
/// A generic material class template that should define how the GBuffer
/// should be built.
/// 
/// A material's shader should write out 4 separate textures:
/// 	0:	Albedo	(rgba)
/// 	1:	Normals	(rgb)
/// 	2:	PBR		(gb)	Note: MUST be actual green and blue channels!
/// 	3:	Emission(rgba)

/// @todo	Implement an automated means of specifying a variable number of
/// 		shaders that can be picked depending on vertex format!
function Material() : U3DObject() constructor {
	#region PROPERTIES
	render_keys = {};
	render_stage = CAMERA_RENDER_STAGE.none;	// Which stage(es) this material renders in
	#endregion
	
	#region METHODS
	/// @desc	Returns if this material is the default "Missing" material. Useful to check
	///			if a material was correctly loaded.
	function get_is_missing_material(){
		return get_index() == U3D.RENDERING.MATERIAL.missing.get_index();
	}
	
	/// @desc	Should apply the necessary shader, uniforms, and textures necessary to build
	///			the GBuffer.
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