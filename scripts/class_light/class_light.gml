/// @about
/// A generic light class that all light types inherit from.
function Light() : Node() constructor {
	#region PROPERTIES
	static ACTIVE_INSTANCE = undefined;	// The currently rendering light
	casts_shadows = false;
	#endregion
	
	#region METHODS
	/// @desc	Whether or not this light will cast some kind of shadow effect
	///			that requires a separate rendering pass.
	function set_casts_shadows(enabled=false){
		casts_shadows = bool(enabled);
	}
	
	/// @desc	Returns the shader index that this light type uses.
	function get_light_shader(){
		return undefined;
	}
	
	function get_shadow_shader(){
		return undefined;
	}
	
	/// @desc	An optional pass that occurs before the lighting is applied but
	///			after the GBuffer has been generated. This function is only called
	///			in the opaque pass and when casts_shadows is enabled
	///			Even if a light type can't cast shadows it should override this
	///			function.
	function render_shadows(eye_id=undefined, body_array=[]){
		throw new Exception("cannot call a virtual function!");
	}
	
	/// @desc	Apply the gbuffer samplers that will be required for the light. These
	///			should be uniforms / textures that could be shared across multiple lights
	///			of the same type.
	/// @note	Current camera and render state can be fetched through the Camera static
	///			class variables.
	function apply_gbuffer(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Apply uniforms specific to this individual light. This is called directly after
	///			apply_gbuffer() on a per-light basis.
	function apply(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	An optional pass that occurs after lighting is rendered in the case
	///			shadows must be handled in a deferred fashion. The function should return
	///			if something was rendered to the 'surface_out'.
	/// @param	{Eye}		eye_id		eye structure that is currently rendering
	/// @param	{surface}	surafce_in	the surface ID the light has just rendered to
	/// @param	{surface}	surface_out	the surface that will be blended into the other light passes
	function apply_shadows(eye_id, surface_in, surface_out){
		return false;
	}
	
	#endregion
	
	#region INIT
	#endregion
}