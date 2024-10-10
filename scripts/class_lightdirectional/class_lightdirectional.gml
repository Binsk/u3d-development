/// @about
/// A directional light that has an equal effect on all elements in the scene.
/// The light faces down the x-axis by default and can be rotated via a
/// quaternion.

/// @desc	a new directional light that casts light evenly on all elements in
///			the scene. While a position is not necessary for lighting up objects
///			it does become necessary for casting shadows and instance 'culling'.
function LightDirectional(rotation=quat(), position=vec()) : Light() constructor {
	#region PROPERTIES
	shader_lighting = shd_lighting_directional;
	light_normal = vec_normalize(quat_rotate_vec(rotation, vec(1, 0, 0)));
	light_color = c_white;
	texture_environment = undefined;
	
	#region SHADER UNIFORMS
	uniform_sampler_albedo = -1;
	uniform_sampler_normal = -1;
	uniform_sampler_pbr = -1;
	uniform_sampler_view = -1;
	uniform_sampler_environment = -1;
	uniform_normal = -1;
	uniform_color = -1;
	uniform_albedo = -1;
	uniform_translucent_pass = -1;
	uniform_environment = -1;
	uniform_inv_projmatrix = -1;
	uniform_inv_viewmatrix = -1;
	uniform_cam_position = -1;
	#endregion
	
	#endregion
	
	#region METHODS
	function render_shadows(gbuffer=[], body_array=[], camera_id=undefined){
/// @stub
	}
	
	function set_color(color=c_white){
		light_color = color;
	}
	
	/// @desc	Sets an environment texture to be used for reflections. If set to anything
	///			other than 'undefined' environmental mapping will be enabled for this light.
	/// @param	{TextureCube}	texture=undefined		a TextureCube texture, specifying the cube-map to use
	function set_environment_texture(texture=undefined){
		if (not is_undefined(texture) and not is_instanceof(texture, TextureCube))
			throw new Exception("invalid type, expected [TextureCube]!");
			
		texture_environment = texture;
	}
	
	function apply_gbuffer(gbuffer, camera_id, is_translucent=false){
		if (uniform_sampler_albedo < 0)
			uniform_sampler_albedo = shader_get_sampler_index(shader_lighting, "u_sAlbedo");
		
		if (uniform_sampler_normal < 0)
			uniform_sampler_normal = shader_get_sampler_index(shader_lighting, "u_sNormal");
		
		if (uniform_sampler_pbr < 0)
			uniform_sampler_pbr = shader_get_sampler_index(shader_lighting, "u_sPBR");
		
		if (uniform_sampler_view < 0)
			uniform_sampler_view = shader_get_sampler_index(shader_lighting, "u_sView");
		
		if (uniform_sampler_environment < 0)
			uniform_sampler_environment = shader_get_sampler_index(shader_lighting, "u_sEnvironment");
		
		if (uniform_normal < 0)
			uniform_normal = shader_get_uniform(shader_lighting, "u_vLightNormal");
		
		if (uniform_color < 0)
			uniform_color = shader_get_uniform(shader_lighting, "u_vLightColor");
		
		if (uniform_inv_projmatrix < 0)
			uniform_inv_projmatrix = shader_get_uniform(shader_lighting, "u_mInvProj");
		
		if (uniform_inv_viewmatrix < 0)
			uniform_inv_viewmatrix = shader_get_uniform(shader_lighting, "u_mInvView");
		
		if (uniform_translucent_pass < 0)
			uniform_translucent_pass = shader_get_uniform(shader_lighting, "u_iTranslucentPass");
		
		if (uniform_environment < 0)
			uniform_environment = shader_get_uniform(shader_lighting, "u_iEnvironment");
		
		if (uniform_cam_position < 0)
			uniform_cam_position = shader_get_uniform(shader_lighting, "u_vCamPosition");
		
		texture_set_stage(uniform_sampler_albedo, gbuffer[$ is_translucent ? CAMERA_GBUFFER.albedo_opaque : CAMERA_GBUFFER.albedo_opaque]);
		texture_set_stage(uniform_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
		texture_set_stage(uniform_sampler_pbr, gbuffer[$ CAMERA_GBUFFER.pbr]);
		texture_set_stage(uniform_sampler_view, gbuffer[$ CAMERA_GBUFFER.view]);
		
		shader_set_uniform_i(uniform_translucent_pass, is_translucent);
		
		if (not is_undefined(texture_environment)){
			texture_set_stage(uniform_sampler_environment, texture_environment.get_texture());
			shader_set_uniform_i(uniform_environment, true);
		}
		else
			shader_set_uniform_i(uniform_environment, false);
		
	}
	
	function apply(){
/// @stub	Figure out why the light needs these two axes inverted
		shader_set_uniform_f(uniform_normal, light_normal.x, -light_normal.y, -light_normal.z);
		shader_set_uniform_f(uniform_color, color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255)
	}

	// Self-executing signal to update light direction so as to prevent re-calculating every frame
	// if the light is static.
	function _signal_rotation_updated(from_quat, to_quat){
		light_normal = vec_normalize(quat_rotate_vec(to_quat, vec(1, 0, 0)));
	}

	#endregion
	
	#region INIT
	set_position(position);
	set_rotation(rotation);
	signaler.add_signal("set_rotation", new Callable(self, _signal_rotation_updated));
	#endregion
}