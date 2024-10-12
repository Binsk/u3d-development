/// ABOUT
/// An ambient light is the simplest of lights and will simply apply its 
/// lighting to everything in the scene equally.
function LightAmbient() : Light() constructor {
	#region PROPERTIES
	shader_lighting = shd_lighting_ambient;
	shader_ssao = shd_ssao;
	surface_ssao = -1;
	light_color = c_white;
	light_intensity = 1.0;		// Intensity of the ambient lighting
	casts_shadows = false; // Toggles SSAO in this case
	texture_environment = undefined;	// If set, an environment map will be reflected; otherwise albedo color is used
	
	ssao_samples = 8;		// Number of samples per pixel (more = less noise, more expensive)
	ssao_radius = 1.0;		// Unitless sample radius around pixel (multiplies against auto-scaled radius)
	ssao_strength = 1.0;	// SSAO contribution (more = darker)
	ssao_bias = 0.01;		// Depth delta cut-off to prevent self-sampling
	ssao_scale = 1.0;		// Scales SSAO depth comparisons (more = larger effect for smaller depth changes)
	ssao_blur_samples = 2;	// `(2x + 1)^2` samples to use when blurring (so 4 = 81 samples) (more = more blurry, more expensive)
	ssao_blur_stride = 1.0;	// Number of texels to stride after each blur sample (more = more blurry but lower quality blur)
	ssao_sample_array = [];	// Pre-computed sample directions to prevent sin/cos in the frag shader
	
	#region SHADER UNIFORMS
	uniform_sampler_albedo = -1;
	uniform_sampler_pbr = -1;
	uniform_sampler_ssao = -1;
	uniform_sampler_view = -1;
	uniform_sampler_normal = -1;
	uniform_sampler_environment = -1;
	uniform_ssao = -1;
	uniform_light_color = -1;
	uniform_light_intensity = -1;
	uniform_texel_size = -1;
	uniform_blur_samples = -1;
	uniform_blur_stride = -1;
	uniform_inv_viewmatrix = -1;
	uniform_inv_projmatrix = -1;
	uniform_environment = -1;
	uniform_cam_position = -1;

	uniform_ssao_sampler_depth = -1;
	uniform_ssao_sampler_normal = -1;
	uniform_ssao_sampler_noise = -1;
	uniform_ssao_invproj = -1;
	uniform_ssao_view = -1;
	uniform_ssao_texelsize = -1;
	uniform_ssao_samples = -1;
	uniform_ssao_sample_array = -1;
	uniform_ssao_radius = -1;
	uniform_ssao_scale = -1;
	uniform_ssao_bias = -1;
	uniform_ssao_intensity = -1;
	
	#endregion
	
	#region METHODS
	/// @desc	Sets the render properties of the SSAO pass. Note that shadows
	///			must be enabled to allow SSAO to render. If SSAO strength <= 0
	///			then the SSAO pass will simply be skipped.
	///			Property values will highly depend on game asthetics and perceived rendering scale.
	/// @param	{int}	samples=16		how many samples per pixel when generating SSAO (more = less noise)
	/// @param	{real}	strength=1.0	how intense the SSAO effect is (higher = darker)
	/// @param	{real}	radius=0.5		radius scalar for sampling distance from original point (higher = wider SSAO effect)
	/// @param	{int}	blur_passes=2	blur pass multiplier for SSAO application where the value will be (2x + 1)^2 (more = blurrier)
	/// @param	{real}	blur_stride=1.0	number of texels to stride per blur pass (more = blurrier but lower quality blur)
	function set_ssao_properties(samples=16, strength=1.0, radius=1.0, bias=0.01, scale=1.0, blur_passes=2, blur_stride=1.0){
		ssao_samples = floor(clamp(samples, 1, 64)); // Shader is limited to max of 64
		ssao_strength = max(0.0, strength)
		ssao_radius = max(0.0, radius);
		ssao_bias = max(0.0, bias);
		ssao_scale = max(0.0, scale);
		ssao_blur_samples = max(0, blur_passes);
		ssao_blur_stride = blur_stride;
		
		// Pre-compute sample directions for the shader
		ssao_sample_array = array_create(ssao_samples * 2.0, 0);
		var dx = (pi * 2.0) / ssao_samples;
		for (var i = 0; i < ssao_samples; ++i){
			var length = choose(0.25, 0.5, 0.75, 1.0); // Length also scales in shader, this helps fill the hemisphere, though
			ssao_sample_array[i * 2] = cos(i * dx) * length;
			ssao_sample_array[i * 2 + 1] = sin(i * dx) * length;
		}
	}
	
	/// @desc	Enables / Disables ambient occlusion for this light. Same as enabling shadows 
	///			since AO is an ambient light's 'shadow'. Simply here for naming convenience.
	function set_ambient_occlusion(enabled=false){
		set_casts_shadows(enabled);
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
		if (uniform_ssao_sampler_noise < 0)
			uniform_ssao_sampler_noise = shader_get_sampler_index(shader_ssao, "u_sNoise");
		if (uniform_ssao_invproj < 0)
			uniform_ssao_invproj = shader_get_uniform(shader_ssao, "u_mInvProj");
		if (uniform_ssao_view < 0)
			uniform_ssao_view = shader_get_uniform(shader_ssao, "u_mView");
		if (uniform_ssao_texelsize < 0)
			uniform_ssao_texelsize = shader_get_uniform(shader_ssao, "u_vTexelSize");
		if (uniform_ssao_samples < 0)
			uniform_ssao_samples = shader_get_uniform(shader_ssao, "u_iSamples");
		if (uniform_ssao_sample_array < 0)
			uniform_ssao_sample_array = shader_get_uniform(shader_ssao, "u_vaSampleDirections");
		if (uniform_ssao_radius < 0)
			uniform_ssao_radius = shader_get_uniform(shader_ssao, "u_fSampleRadius");
		if (uniform_ssao_scale < 0)
			uniform_ssao_scale = shader_get_uniform(shader_ssao, "u_fScale");
		if (uniform_ssao_bias < 0)
			uniform_ssao_bias = shader_get_uniform(shader_ssao, "u_fBias");
		if (uniform_ssao_intensity < 0)
			uniform_ssao_intensity = shader_get_uniform(shader_ssao, "u_fIntensity");
			
		if (not surface_exists(surface_ssao))
			surface_ssao = surface_create(camera_id.buffer_width, camera_id.buffer_height, surface_r8unorm);
		
		// Render SSAO intensity:
		shader_set(shader_ssao);
		surface_set_target(surface_ssao);
		
		texture_set_stage(uniform_ssao_sampler_depth, gbuffer[$ CAMERA_GBUFFER.depth_opaque]);
		texture_set_stage(uniform_ssao_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
		texture_set_stage(uniform_ssao_sampler_noise, sprite_get_texture(spr_ssao_noise, 0));
		
		shader_set_uniform_matrix_array(uniform_ssao_invproj, matrix_get_inverse(camera_id.get_projection_matrix()));
		shader_set_uniform_f_array(uniform_ssao_view, matrix_to_matrix3(camera_id.get_view_matrix()));
		shader_set_uniform_f(uniform_ssao_texelsize, texture_get_texel_width(gbuffer[$ CAMERA_GBUFFER.normal]), texture_get_texel_height(gbuffer[$ CAMERA_GBUFFER.normal]));
		shader_set_uniform_i(uniform_ssao_samples, ssao_samples);
		shader_set_uniform_f_array(uniform_ssao_sample_array, ssao_sample_array);
		shader_set_uniform_f(uniform_ssao_radius, ssao_radius);
		shader_set_uniform_f(uniform_ssao_scale, ssao_scale);
		shader_set_uniform_f(uniform_ssao_bias, ssao_bias);
		shader_set_uniform_f(uniform_ssao_intensity, ssao_strength);
		
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
	
	function apply_gbuffer(gbuffer, camera_id, is_translucent=false){
		if (uniform_sampler_albedo < 0)
			uniform_sampler_albedo = shader_get_sampler_index(shader_lighting, "u_sAlbedo");
		
		if (uniform_sampler_pbr < 0)
			uniform_sampler_pbr = shader_get_sampler_index(shader_lighting, "u_sPBR");
			
		if (uniform_sampler_ssao < 0)
			uniform_sampler_ssao = shader_get_sampler_index(shader_lighting, "u_sSSAO");
		
		if (uniform_sampler_view < 0)
			uniform_sampler_view = shader_get_sampler_index(shader_lighting, "u_sView");
		
		if (uniform_sampler_normal < 0)
			uniform_sampler_normal = shader_get_sampler_index(shader_lighting, "u_sNormal");
		
		if (uniform_sampler_environment < 0)
			uniform_sampler_environment = shader_get_sampler_index(shader_lighting, "u_sEnvironment");
		
		if (uniform_ssao < 0)
			uniform_ssao = shader_get_uniform(shader_lighting, "u_iSSAO");
		
		if (uniform_light_intensity < 0)
			uniform_light_intensity = shader_get_uniform(shader_lighting, "u_fIntensity");
		
		if (uniform_light_color < 0)
			uniform_light_color = shader_get_uniform(shader_lighting, "u_vLightColor");
		
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
		
		texture_set_stage(uniform_sampler_albedo, gbuffer[$ is_translucent ? CAMERA_GBUFFER.albedo_translucent : CAMERA_GBUFFER.albedo_opaque]);
		texture_set_stage(uniform_sampler_pbr, gbuffer[$ CAMERA_GBUFFER.pbr]);
		texture_set_stage(uniform_sampler_view, gbuffer[$ CAMERA_GBUFFER.view]);
		
		if (not is_undefined(texture_environment)){
			texture_set_stage(uniform_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
			texture_set_stage(uniform_sampler_environment, texture_environment.get_texture());
			shader_set_uniform_i(uniform_environment, true);
		}
		else
			shader_set_uniform_i(uniform_environment, false);
		
		if (not is_translucent and casts_shadows and surface_exists(surface_ssao) and ssao_strength > 0){
			texture_set_stage(uniform_sampler_ssao, surface_get_texture(surface_ssao));
			shader_set_uniform_f(uniform_texel_size, 1.0 / surface_get_width(surface_ssao), 1.0 / surface_get_height(surface_ssao));
			shader_set_uniform_i(uniform_blur_samples, ssao_blur_samples);
			shader_set_uniform_f(uniform_blur_stride, ssao_blur_stride);
		}
		
		shader_set_uniform_i(uniform_ssao, not is_translucent and casts_shadows);
	}
	
	function apply(){
		shader_set_uniform_f(uniform_light_color, color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255);
		shader_set_uniform_f(uniform_light_intensity, light_intensity);
	}
	
	super.mark("free");
	function free(){
		super.execute("free");
		
		if (surface_exists(surface_ssao))
			surface_free(surface_ssao);
		
		surface_ssao = -1;
	}
	#endregion
	
	#region INIT
	set_ssao_properties(ssao_samples, ssao_strength, ssao_radius, ssao_bias, ssao_scale, ssao_blur_samples, ssao_blur_stride);
	#endregion
}