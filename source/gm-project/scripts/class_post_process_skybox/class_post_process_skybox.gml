/// @about
/// Renders a skybox to the render where alpha is < 1.0.

/// @param	{TextureCube}	cubemap		cube map texture to use for the skybox
function PPFXSkybox(cubemap=undefined) : PostProcessFX(shd_skybox) constructor {
	#region METHODS
	function set_environment_texture(cubemap){
		if (not is_instanceof(cubemap, TextureCube) and not is_undefined(cubemap))
			throw new Exception("invalid type, expected [TextureCube]!");
		
		samplers.u_sEnvironment = cubemap;
	}
	
	super.register("render");
	function render(surface_out){
		if (is_undefined(samplers.u_sEnvironment))
			return false;
		
		return super.execute("render", [surface_out]);
	}
	#endregion
	
	#region INIT
	if (not is_instanceof(cubemap, TextureCube) and not is_undefined(cubemap))
		throw new Exception("invalid type, expected [TextureCube]!");
		
	self.set_custom_samplers({
		"u_sEnvironment" : cubemap
	});
	#endregion
}