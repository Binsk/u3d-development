/// @about
/// A generic light class that all light types inherit from. Note that the shader
/// should ONLY be set in the constructor otherwise uniforms will need to be reset.
function Light() : Node() constructor {
	#region PROPERTIES
	shader_lighting = undefined;
	casts_shadows = false;
	#endregion
	
	#region METHODS
	/// @desc	Returns the shader index that this light type uses.
	function get_shader(){
		return shader_lighting;
	}
	
	/// @desc	An optional pass that occurs before the lighting is applied but
	///			after the GBuffer has been generated. This function is only called
	///			in the opaque pass and when casts_shadows is enabled
	///			Even if a light type can't cast shadows it should override this
	///			function.
	function render_shadows(gbuffer=[], body_array=[]){
		throw new Exception("cannot call a virtual function!");
	}
	
	/// @desc	Apply the gbuffer samplers that will be required for the light.
	///			The gbuffer will be an array of textures referenceable via
	///			CAMERA_GBUFFER. The only textures that should NOT be accessed
	///			are the out_opaque and out_translucent textures.
	/// @param	{array}		gbuffer					array of gbuffer textures to sample from
	/// @param	{bool}		is_translucent=false	whether or not this is the translucent pass or not
	function apply_gbuffer(gbuffer, is_translucent=false){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Apply uniforms relevant to the light.
	function apply(){
		throw new Exception("cannot call virtual function!");
	}
	
	#endregion
	
	#region INIT
	#endregion
}