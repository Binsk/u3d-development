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
	
	#region SHADER UNIFORMS
	uniform_sampler_albedo = -1;
	uniform_sampler_normal = -1;
	uniform_sampler_pbr = -1;
	uniform_normal = -1;
	uniform_color = -1;
	uniform_translucent_pass = -1;
	#endregion
	
	#endregion
	
	#region METHODS
	function render_shadows(gbuffer=[], body_array=[], camera_id=undefined){
/// @stub
	}
	
	function apply_gbuffer(gbuffer, is_translucent=false){
		if (uniform_sampler_albedo < 0)
			uniform_sampler_albedo = shader_get_sampler_index(shader_lighting, "u_sAlbedo");
		
		if (uniform_sampler_normal < 0)
			uniform_sampler_normal = shader_get_sampler_index(shader_lighting, "u_sNormal");
		
		if (uniform_sampler_pbr < 0)
			uniform_sampler_pbr = shader_get_sampler_index(shader_lighting, "u_sPBR");
		
		if (uniform_normal < 0)
			uniform_normal = shader_get_uniform(shader_lighting, "u_vLightNormal");
		
		if (uniform_color < 0)
			uniform_color = shader_get_uniform(shader_lighting, "u_vLightColor");
		
		if (uniform_translucent_pass < 0)
			uniform_translucent_pass = shader_get_uniform(shader_lighting, "u_iTranslucentPass");
		
		texture_set_stage(uniform_sampler_albedo, gbuffer[$ is_translucent ? CAMERA_GBUFFER.albedo_opaque : CAMERA_GBUFFER.albedo_opaque]);
		texture_set_stage(uniform_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
		texture_set_stage(uniform_sampler_pbr, gbuffer[$ CAMERA_GBUFFER.pbr]);
		
		shader_set_uniform_i(uniform_translucent_pass, is_translucent);
	}
	
	function apply(){
		// Convert light data into view space as that is where we calculate everything
		var light_normal_view = matrix_transform_vertex(other.get_view_matrix(), light_normal.x, light_normal.y, light_normal.z, 0.0);
		shader_set_uniform_f(uniform_normal, -light_normal_view[0], -light_normal_view[1], -light_normal_view[2]);
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