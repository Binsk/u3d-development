/// @about
/// A generic light class that all light types inherit from. Note that the shader
/// should ONLY be set in the constructor otherwise uniforms will need to be reset.
function Light() : Node() constructor {
	#region PROPERTIES
	shader_lighting = undefined;
	casts_shadows = false;
	#endregion
	
	#region METHODS
	
	function set_casts_shadows(enabled=false){
		casts_shadows = bool(enabled);
	}
	
	/// @desc	Returns the shader index that this light type uses.
	function get_shader(){
		return shader_lighting;
	}
	
	/// @desc	An optional pass that occurs before the lighting is applied but
	///			after the GBuffer has been generated. This function is only called
	///			in the opaque pass and when casts_shadows is enabled
	///			Even if a light type can't cast shadows it should override this
	///			function.
	function render_shadows(gbuffer=[], body_array=[], camera_id=undefined){
		throw new Exception("cannot call a virtual function!");
	}
	
	/// @desc	Apply the gbuffer samplers that will be required for the light.
	///			The gbuffer will be an array of textures referenceable via
	///			CAMERA_GBUFFER. The only textures that should NOT be accessed
	///			are the light_opaque and light_translucent textures.
	/// @param	{array}		gbuffer					array of gbuffer textures to sample from
	/// @param	{Camera}	camera_id				id of the currently rendering camera
	/// @param	{bool}		is_translucent=false	whether or not this is the translucent pass or not
	function apply_gbuffer(gbuffer, camera_id, is_translucent=false){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Apply uniforms relevant to the light.
	function apply(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	An optional pass that occurs after lighting is rendered in the case
	///			shadows must be handled in a deferred fashion. The function should return
	///			if something was rendered to the 'surface_out'.
	function apply_shadows(surface_in, surface_out){
		return false;
	}
	
	#endregion
	
	#region INIT
	#endregion
}