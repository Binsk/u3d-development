/// ABOUT
/// An ambient light is the simplest of lights and will simply apply its 
/// lighting to everything in the scene equally.

/// @stub	Look into https://computergraphics.stackexchange.com/questions/3955/physically-based-shading-ambient-indirect-lighting
///			for improved ambient lighting effects.
function LightAmbient() : Light() constructor {
	#region PROPERTIES
	shader_lighting = shd_lighting_ambient;
	shader_ssao = shd_ssao;
	surface_ssao = -1;
	albedo = c_white;
	intensity = 1.0;		// Intensity of the ambient lighting
	casts_shadows = false; // Toggles SSAO in this case
	texture_environment = undefined;	// If set, an environment map will be reflected; otherwise albedo color is used
	
	ssao_samples = 16;		// Number of samples to perform when rendering SSAO (more = cleaner but more expensive)
	ssao_radius = 0.5;		// Generic sample radius scalar (radius is auto-calculated based on fragment depth + zfar; this multiplies against that)
	ssao_strength = 1.0;	// Scales SSAO strength / area together
	ssao_blur_samples = 2;	// `(2x + 1)^2` samples to use when blurring (so 4 = 81 samples)
	ssao_blur_stride = 1.0;	// Number of texels to stride after each sample
	ssao_normal_bias = 0.0;	// Multiplies against normal comparison result ([0..1], larger attempts to remove noise on flat surfaces at cost of accuracy)
							// Generally cartoony / flat shading can use high bias while realistic should use low
	
	#region SHADER UNIFORMS
	uniform_sampler_albedo = -1;
	uniform_sampler_pbr = -1;
	uniform_sampler_ssao = -1;
	uniform_sampler_depth = -1;
	uniform_sampler_normal = -1;
	uniform_sampler_environment = -1;
	uniform_ssao = -1;
	uniform_albedo = -1;
	uniform_intensity = -1;
	uniform_texel_size = -1;
	uniform_blur_samples = -1;
	uniform_blur_stride = -1;
	uniform_inv_viewmatrix = -1;
	uniform_inv_projmatrix = -1;
	uniform_environment = -1;
	uniform_cam_position = -1;
	
	uniform_ssao_sampler_normal = -1;
	uniform_ssao_sampler_depth = -1;
	uniform_ssao_samples = -1;
	uniform_ssao_falloff = -1;
	uniform_ssao_radius = -1;
	uniform_ssao_strength = -1;
	uniform_ssao_area = -1;
	uniform_ssao_normal_bias = -1;
	uniform_ssao_view_matrix = -1;
	#endregion
	#endregion
	
	#region METHODS
	/// @desc	Sets the render properties of the SSAO pass. Note that shadows
	///			must be enabled to allow SSAO to render. If SSAO strength <= 0
	///			then the SSAO pass will simply be skipped.
	///			Property values will highly depend on game asthetics and perceived rendering scale.
	/// @param	{int}	samples=16		how many samples per pixel when generating SSAO (more = less noise)
	/// @param	{real}	strength=1.0	how intense the SSAO effect is (higher = darker)
	/// @param	{real}	radius=0.5		radius scalar for sampling distance from original point (higher = wider SSAO effect)
	/// @param	{real}	normal_bias=1.0	[0..1], how strong the normal comparison bias should be (larger=less noise on flat surfaces but less precise)
	/// @param	{int}	blur_passes=2	blur pass multiplier for SSAO application where the value will be (2x + 1)^2 (more = blurrier)
	/// @param	{real}	blur_stride=1.0	number of texels to stride per blur pass (more = blurrier but lower quality blur)
	function set_ssao_properties(samples=16, strength=1.0, radius=0.5, normal_bias=1.0, blur_passes=2, blur_stride=1.0){
		ssao_samples = max(1.0, samples);
		ssao_strength = max(0.0, strength)
		ssao_radius = max(0.0, radius);
		ssao_normal_bias = clamp(normal_bias, 0, 1);
		ssao_blur_samples = max(0, blur_passes);
		ssao_blur_stride = blur_stride;
	}
	
	/// @desc	Enables / Disables ambient occlusion for this light.
	function set_ambient_occlusion(enabled=false){
		set_casts_shadows(enabled);
	}
	
	function set_environment_texture(texture=undefined){
		texture_environment = texture;
	}
	
	/// @desc	Set the lighting intensity which multplies against the light's
	///			color in the shader.
	function set_intensity(intensity=1.0){
		self.intensity = max(0, intensity);
	}
	
	function render_shadows(gbuffer=[], body_array=[], camera_id=undefined){
		if (ssao_strength <= 0)
			return;
			
		if (uniform_ssao_sampler_depth < 0)
			uniform_ssao_sampler_depth = shader_get_sampler_index(shader_ssao, "u_sDepth");
		
		if (uniform_ssao_sampler_normal < 0)
			uniform_ssao_sampler_normal = shader_get_sampler_index(shader_ssao, "u_sNormal");
		
		if (uniform_ssao_samples < 0)
			uniform_ssao_samples = shader_get_uniform(shader_ssao, "u_iSamples");
		
		if (uniform_ssao_falloff < 0)
			uniform_ssao_falloff = shader_get_uniform(shader_ssao, "u_fFalloff");
		
		if (uniform_ssao_radius < 0)
			uniform_ssao_radius = shader_get_uniform(shader_ssao, "u_fRadius");
		
		if (uniform_ssao_strength < 0)
			uniform_ssao_strength = shader_get_uniform(shader_ssao, "u_fStrength");
		
		if (uniform_ssao_area < 0)
			uniform_ssao_area = shader_get_uniform(shader_ssao, "u_fArea");
		
		if (uniform_ssao_normal_bias < 0)
			uniform_ssao_normal_bias = shader_get_uniform(shader_ssao, "u_fNormalBias");
		
		if (uniform_ssao_view_matrix < 0)
			uniform_ssao_view_matrix = shader_get_uniform(shader_ssao, "u_mView");

		if (not surface_exists(surface_ssao))
			surface_ssao = surface_create(camera_id.buffer_width, camera_id.buffer_height, surface_r32float);
		
		// Render SSAO intensity:
		shader_set(shader_ssao);
		surface_set_target(surface_ssao);
		
		shader_set_uniform_i(uniform_ssao_samples, ssao_samples);
		shader_set_uniform_f(uniform_ssao_falloff, 0.000001 / ((camera_id.zfar - camera_id.znear) / 1024.0));
		shader_set_uniform_f(uniform_ssao_radius, 0.0008 / ((camera_id.zfar - camera_id.znear) / 1024.0) * ssao_radius);
		shader_set_uniform_f(uniform_ssao_strength, ssao_strength);
		shader_set_uniform_f(uniform_ssao_area, lerp(0.1, 0.0075, ssao_strength));
		shader_set_uniform_f(uniform_ssao_normal_bias, ssao_normal_bias);
		shader_set_uniform_f_array(uniform_ssao_view_matrix, matrix_to_matrix3(camera_id.get_view_matrix()));
		texture_set_stage(uniform_ssao_sampler_depth, gbuffer[$ CAMERA_GBUFFER.depth_opaque]);
		texture_set_stage(uniform_ssao_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
		
		draw_clear(c_black);
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(camera_id.buffer_width, 0, 1, 0);
		draw_vertex_texture(0, camera_id.buffer_height, 0, 1);
		draw_vertex_texture(camera_id.buffer_width, camera_id.buffer_height, 1, 1);
		draw_primitive_end();
		surface_reset_target();
		shader_reset();
	}
	
	function apply_gbuffer(gbuffer, is_translucent=false){
		if (uniform_sampler_albedo < 0)
			uniform_sampler_albedo = shader_get_sampler_index(shader_lighting, "u_sAlbedo");
		
		if (uniform_sampler_pbr < 0)
			uniform_sampler_pbr = shader_get_sampler_index(shader_lighting, "u_sPBR");
			
		if (uniform_sampler_ssao < 0)
			uniform_sampler_ssao = shader_get_sampler_index(shader_lighting, "u_sSSAO");
		
		if (uniform_sampler_depth < 0)
			uniform_sampler_depth = shader_get_sampler_index(shader_lighting, "u_sDepth");
		
		if (uniform_sampler_normal < 0)
			uniform_sampler_normal = shader_get_sampler_index(shader_lighting, "u_sNormal");
		
		if (uniform_sampler_environment < 0)
			uniform_sampler_environment = shader_get_sampler_index(shader_lighting, "u_sEnvironment");
		
		if (uniform_ssao < 0)
			uniform_ssao = shader_get_uniform(shader_lighting, "u_iSSAO");
		
		if (uniform_intensity < 0)
			uniform_intensity = shader_get_uniform(shader_lighting, "u_fIntensity");
		
		if (uniform_albedo < 0)
			uniform_albedo = shader_get_uniform(shader_lighting, "u_vAlbedo");
		
		if (uniform_texel_size < 0)
			uniform_texel_size = shader_get_uniform(shader_lighting, "u_vTexelSize");
		
		if (uniform_blur_samples < 0)
			uniform_blur_samples = shader_get_uniform(shader_lighting, "u_iBlurSamples");
		
		if (uniform_blur_stride < 0)
			uniform_blur_stride = shader_get_uniform(shader_lighting, "u_fBlurStride");
		
		if (uniform_inv_projmatrix < 0)
			uniform_inv_projmatrix = shader_get_uniform(shader_lighting, "u_mInvProj");
		
		if (uniform_inv_viewmatrix < 0)
			uniform_inv_viewmatrix = shader_get_uniform(shader_lighting, "u_mInvView");
		
		if (uniform_environment < 0)
			uniform_environment = shader_get_uniform(shader_lighting, "u_iEnvironment");
			
		if (uniform_cam_position < 0)
			uniform_cam_position = shader_get_uniform(shader_lighting, "u_vCamPosition");
		
		texture_set_stage(uniform_sampler_albedo, gbuffer[$ is_translucent ? CAMERA_GBUFFER.albedo_opaque : CAMERA_GBUFFER.albedo_opaque]);
		texture_set_stage(uniform_sampler_pbr, gbuffer[$ CAMERA_GBUFFER.pbr]);
		
		if (not is_undefined(texture_environment)){
			texture_set_stage(uniform_sampler_depth, gbuffer[$ CAMERA_GBUFFER.depth_opaque + is_translucent]);
			texture_set_stage(uniform_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
			texture_set_stage(uniform_sampler_environment, texture_environment);
			shader_set_uniform_i(uniform_environment, true);
		}
		else
			shader_set_uniform_i(uniform_environment, false);
		
		shader_set_uniform_matrix_array(uniform_inv_projmatrix, matrix_get_inverse(other.get_projection_matrix()));
		shader_set_uniform_matrix_array(uniform_inv_viewmatrix, matrix_get_inverse(other.get_view_matrix()));
		shader_set_uniform_f(uniform_cam_position, other.position.x, other.position.y, other.position.z);
		
		if (not is_translucent and casts_shadows and surface_exists(surface_ssao) and ssao_strength > 0){
			texture_set_stage(uniform_sampler_ssao, surface_get_texture(surface_ssao));
			shader_set_uniform_f(uniform_texel_size, 1.0 / surface_get_width(surface_ssao), 1.0 / surface_get_height(surface_ssao));
			shader_set_uniform_i(uniform_blur_samples, ssao_blur_samples);
			shader_set_uniform_f(uniform_blur_stride, ssao_blur_stride);
		}
		
		shader_set_uniform_i(uniform_ssao, not is_translucent and casts_shadows);
	}
	
	function apply(){
		shader_set_uniform_f(uniform_albedo, color_get_red(albedo) / 255, color_get_green(albedo) / 255, color_get_blue(albedo) / 255);
		shader_set_uniform_f(uniform_intensity, intensity);
	}
	
	super.mark("free");
	function free(){
		super.execute("free");
		
		if (surface_exists(surface_ssao))
			surface_free(surface_ssao);
		
		surface_ssao = -1;
	}
	#endregion
}