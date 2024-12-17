function LightPoint(position=vec()) : Light() constructor {
	#region PROPERTIES
	light_color = c_white;
	light_intensity = 1.0;
	light_range = infinity;	// How far the light can reach
	texture_environment = undefined;
	self.position = position;
	#endregion
	
	#region METHODS
	function set_casts_shadows(enabled){
		throw new Exception("point shadows not yet implemented!");
	}
	
	/// @desc	Sets the color of the light's albedo.
	function set_color(color=c_white){
		light_color = color;
	}
	
	/// @desc	Set the lighting intensity which multiplies against the light's
	///			color in the shader.
	function set_intensity(intensity=1.0){
		self.light_intensity = max(0, intensity);
	}
	
	function set_range(range=infinity){
		light_range = max(0, range);
	}
	
	/// @desc	Sets an environment texture to be used for reflections. If set to anything
	///			other than 'undefined' environmental mapping will be enabled for this light.
	/// @param	{TextureCube}	texture	a TextureCube texture, specifying the cube-map to use
	function set_environment_texture(texture=undefined){
		if (not is_undefined(texture) and not is_instanceof(texture, TextureCube))
			throw new Exception("invalid type, expected [TextureCube]!");
			
		replace_child_ref(texture, texture_environment);
		texture_environment = texture;
	}
	
	/// @desc	Returns the shader index that this light type uses.
	function get_light_shader(){
		return shd_lighting_point;
	}
	
	function apply_gbuffer(){
		var camera_id = Camera.ACTIVE_INSTANCE;
		var is_translucent = Camera.get_is_translucent_stage();
		sampler_set("u_sAlbedo", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.albedo]);
		sampler_set("u_sDepth", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.depth]);
		sampler_set("u_sNormal", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal]);
		sampler_set("u_sPBR", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.pbr]);
		sampler_set("u_sView", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.view]);
		
		if (not is_undefined(texture_environment) and camera_id.get_has_render_flag(CAMERA_RENDER_FLAG.environment))
			texture_environment.apply("u_sEnvironment");
		else
			uniform_set("u_iEnvironment", shader_set_uniform_i, false);

		uniform_set("u_mInvProj", shader_set_uniform_matrix, Eye.ACTIVE_INSTANCE.get_inverse_projection_matrix());
		uniform_set("u_mInvView", shader_set_uniform_matrix, Eye.ACTIVE_INSTANCE.get_inverse_view_matrix());
		uniform_set("u_vLightPosition", shader_set_uniform_f, [position.x, position.y, position.z]);
	}
	
	function apply(){
		uniform_set("u_vLightColor", shader_set_uniform_f, [color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255]);
		uniform_set("u_fIntensity", shader_set_uniform_f, light_intensity);
		uniform_set("u_fRange", shader_set_uniform_f, is_infinity(light_range) ? 1000000 : light_range);
	}
	#endregion
	
	
}