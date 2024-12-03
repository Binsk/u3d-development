/// @about
/// An ambient light is the simplest of lights and will simply apply its 
/// lighting to everything in the scene equally.
function LightAmbient() : Light() constructor {
	#region PROPERTIES
	surface_ssao = -1;
	light_color = c_white;
	light_intensity = 1.0;		// Intensity of the ambient lighting
	casts_shadows = false;		// Toggles SSAO in this case
	texture_environment = undefined;	// If set, an environment map will be reflected; otherwise black is used
	
	ssao_samples = 8;		// Number of samples per pixel (more = less noise, more expensive)
	ssao_radius = 1.0;		// Unitless sample radius around pixel (multiplies against auto-scaled radius)
	ssao_strength = 1.0;	// SSAO contribution (more = darker)
	ssao_bias = 0.01;		// Depth delta cut-off to prevent self-sampling
	ssao_scale = 1.0;		// Scales SSAO depth comparisons (more = larger effect for smaller depth changes)
	ssao_blur_samples = 2;	// `(2x + 1)^2` samples to use when blurring (so 4 = 81 samples) (more = more blurry, more expensive)
	ssao_blur_stride = 1.0;	// Number of texels to stride after each blur sample (more = more blurry but lower quality blur)
	ssao_sample_array = [];	// Pre-computed sample directions to prevent sin/cos in the frag shader
	#endregion
	
	#region METHODS
	/// @desc	Sets the render properties of the SSAO pass. Note that shadows
	///			must be enabled to allow SSAO to render. If SSAO strength <= 0
	///			then the SSAO pass will simply be skipped.
	///			Property values will highly depend on game asthetics and perceived rendering scale.
	/// @param	{real}	samples		how many samples per pixel when generating SSAO (more = less noise)
	/// @param	{real}	strength	how intense the SSAO effect is (higher = darker)
	/// @param	{real}	radius		radius scalar for sampling distance from original point (higher = wider SSAO effect)
	/// @param	{real}	bias		normal bias when comparing surface directions (larger = less likely to cause SSAO)
	/// @param	{real}	scale		depth scale between samples (higher = greater perceived distance between samples)
	/// @param	{real}	blur_passes	blur pass multiplier for SSAO application where the value will be (2x + 1)^2 (more = blurrier)
	/// @param	{real}	blur_stride	number of texels to stride per blur pass (more = blurrier but lower quality blur)
	function set_ssao_properties(samples=8, strength=1.0, radius=1.0, bias=0.01, scale=1.0, blur_passes=2, blur_stride=1.0){
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
	
	/// @desc	Sets the color of the light's albedo.
	function set_color(color=c_white){
		light_color = color;
	}
	
	/// @desc	Sets an environment texture to be used for reflections. If set to anything
	///			other than 'undefined' environmental mapping will be enabled for this light.
	/// @param	{TextureCube}	texture		a TextureCube texture, specifying the cube-map to use
	function set_environment_texture(texture=undefined){
		if (not is_undefined(texture) and not is_instanceof(texture, TextureCube))
			throw new Exception("invalid type, expected [TextureCube]!");
			
		replace_child_ref(texture, texture_environment);
		texture_environment = texture;
	}
	
	/// @desc	Set the lighting intensity which multiplies against the light's
	///			color in the shader.
	function set_intensity(intensity=1.0){
		self.light_intensity = max(0, intensity);
	}
	
	function get_light_shader(){
		return shd_lighting_ambient;
	}
	
	function get_shadow_shader(){
		return shd_ssao;
	}
	
	function render_shadows(eye_id=undefined, body_array=[]){
		if (ssao_strength <= 0)
			return;
			
		var camera_id = eye_id.get_camera();

		if (surface_exists(surface_ssao) and (surface_get_width(surface_ssao) != camera_id.buffer_width or surface_get_height(surface_ssao) != camera_id.buffer_height))
			surface_free(surface_ssao);
			
		if (not surface_exists(surface_ssao))
			surface_ssao = surface_create(camera_id.buffer_width, camera_id.buffer_height, not surface_format_is_supported(surface_r8unorm) ? surface_rgba8unorm : surface_r8unorm);
		
		// Render SSAO intensity:
		shader_set(get_shadow_shader());
		surface_set_target(surface_ssao);
		
		sampler_set("u_sDepth", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.depth]);
		sampler_set("u_sNormal", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal]);
		sampler_set("u_sNoise", sprite_get_texture(spr_default_ssao_noise, 0));
		
		uniform_set("u_mInvProj", shader_set_uniform_matrix_array, [eye_id.get_inverse_projection_matrix()]);
		uniform_set("u_mView", shader_set_uniform_f_array, [matrix_to_matrix3(eye_id.get_view_matrix())]);
		uniform_set("u_vTexelSize", shader_set_uniform_f, [texture_get_texel_width(camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal]), texture_get_texel_height(camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal])]);
		uniform_set("u_iSamples", shader_set_uniform_i, [ssao_samples]);
		uniform_set("u_vaSampleDirections", shader_set_uniform_f_array, [ssao_sample_array]);
		uniform_set("u_fSampleRadius", shader_set_uniform_f, [ssao_radius]);
		uniform_set("u_fScale", shader_set_uniform_f, [ssao_scale]);
		uniform_set("u_fBias", shader_set_uniform_f, [ssao_bias]);
		uniform_set("u_fIntensity", shader_set_uniform_f, [ssao_strength]);
		
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
	
	function apply_gbuffer(){
		var camera_id = Camera.ACTIVE_INSTANCE;
		var is_translucent = Camera.get_is_translucent_stage();
		
		sampler_set("u_sAlbedo", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.albedo]);
		sampler_set("u_sPBR", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.pbr]);
		sampler_set("u_sView", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.view]);
		
		if (not is_undefined(texture_environment) and camera_id.get_has_render_flag(CAMERA_RENDER_FLAG.environment)){
			sampler_set("u_sNormal", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal]);
			texture_environment.apply("u_sEnvironment");
		}
		else
			uniform_set("u_iEnvironment", shader_set_uniform_i, false);
		
		if (not is_translucent and casts_shadows and surface_exists(surface_ssao) and ssao_strength > 0 and camera_id.get_has_render_flag(CAMERA_RENDER_FLAG.shadows)){
			sampler_set("u_sSSAO", surface_get_texture(surface_ssao));
			
			uniform_set("u_vTexelSize", shader_set_uniform_f, [1.0 / surface_get_width(surface_ssao), 1.0 / surface_get_height(surface_ssao)]);
			uniform_set("u_iBlurSamples", shader_set_uniform_i, ssao_blur_samples);
			uniform_set("u_fBlurStride", shader_set_uniform_f, ssao_blur_stride);
		}
		
		uniform_set("u_iSSAO", shader_set_uniform_i, not is_translucent and casts_shadows and camera_id.get_has_render_flag(CAMERA_RENDER_FLAG.shadows));
	}
	
	function apply(){
		uniform_set("u_vLightColor", shader_set_uniform_f, [color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255]);
		uniform_set("u_fIntensity", shader_set_uniform_f, light_intensity);
	}
	
	super.register("free");
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