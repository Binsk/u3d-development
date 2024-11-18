/// @about
/// This PPFX effect adds bloom to the final output. Note that the swap surfaces 
/// must re-allocate if the camera size changes, as such it is best to have a 
/// SEPARATE instance of bloom for each camera instead of sharing one instance!
/// @note	Threshold will HIGHLY depend on your scene and lighting setup! If bloom
///			doesn't appear or appears to blow everything out make sure to try adjusting
///			the threshold first.

/// @param	{real}	luminance_threshold	The threshold at which bloom starts appearing
/// @param	{real}	resolution_scale		the scale relative to the camera's render resolution to render at
/// @param	{real}	blur_passes				number of times to blur the bloom
/// @param	{real}	blur_stride				how many texels to stride in a blur pass (more = wider bloom, possible checkered artifacts)
function PPFXBloom(luminance_threshold=1.0, resolution_scale=0.5, blur_passes=5, blur_stride=1.0) : PostProcessFX(shd_luminance_isolate) constructor {
	#region PROPERTIES
	threshold = luminance_threshold;
	scale = resolution_scale;
	passes = max(2, blur_passes);
	stride = max(1, blur_stride);
	surface_a = -1;	// Surfaces for rendering 
	surface_b = -1;
	#endregion
	
	#region METHODS
	
	/// @desc	The 'brightness' level of a pixel required before bloom starts taking effect.
	///			Note: This is applied in linear space before tonemapping. Anything below the
	///			specified level will be rendered normally, anything above will have bloom applied.
	function set_luminance_threshold(threshold){
		self.threshold = threshold;
	}
	
	/// @desc	The scale of bloom pass relative to the camera's render resolution. Smaller is
	///			faster and has a larger radius but will be lower quality.
	function set_resolution_scale(scale){
		self.scale = scale;
	}
	
	/// @desc	The number of gaussian blur passes to process over the bloom. Passes are directional
	///			so there need to be at least 2. More passes = smoother result and can help compensate
	///			for low resolution scale. Cost greatly increases with render scale.
	function set_blur_passes(passes){
		self.passes = max(2, passes);
	}
	
	/// @desc	The number of texels that should be walked per blur sample. More will result in a wider
	///			blur but at the cost of quality.
	function set_blur_stride(stride){
		self.stride = max(1, stride);
	}
	
	super.register("render");
	function render(surface_out){
		if (not is_enabled)
			return;
			
		var buffer_width = Camera.ACTIVE_INSTANCE.buffer_width;
		var buffer_height = Camera.ACTIVE_INSTANCE.buffer_height;
		var gbuffer = Camera.ACTIVE_INSTANCE.gbuffer.textures;
		
		var pass_width = floor(buffer_width * scale);
		var pass_height = floor(buffer_height * scale);
		
		if (surface_exists(surface_a) and (surface_get_width(surface_a) != pass_width or surface_get_height(surface_a) != pass_height))
			surface_free(surface_a);
			
		if (not surface_exists(surface_a))
			surface_a = surface_create(pass_width, pass_height, surface_rgba16float);
		
		if (surface_exists(surface_b) and (surface_get_width(surface_b) != pass_width or surface_get_height(surface_b) != pass_height))
			surface_free(surface_b);
			
		if (not surface_exists(surface_b))
			surface_b = surface_create(pass_width, pass_height, surface_rgba16float);
		
		surface_clear(surface_a, c_black, 0.0);
		surface_clear(surface_b, c_black, 0.0);
		gpu_set_texrepeat(false);
		
		// Copy the "illuminated" parts to the surface:
		surface_set_target(surface_a);
		if (shader_current() != shader)
			shader_set(shader);
		
		sampler_set("u_sInput", gbuffer[$ CAMERA_GBUFFER.final] ?? -1);
		uniform_set("u_fThreshold", shader_set_uniform_f, threshold);
		
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(pass_width, 0, 1, 0);
		draw_vertex_texture(0, pass_height, 0, 1);
		draw_vertex_texture(pass_width, pass_height, 1, 1);
		draw_primitive_end();
		
		shader_reset();
		surface_reset_target();
		
		// Render blur passes:
		var texel_w, texel_h;
		shader_set(shd_gaussian_13);
		var active_index = 1;
		var d = (passes == 2 ? 90 : 360 / passes);
		for (var i = 0; i < passes; ++i){
			surface_set_target(active_index ? surface_b : surface_a);
			uniform_set("u_vDirection", shader_set_uniform_f, [dcos(d * i), dsin(d * i)]);
			
			texel_w = 1.0 / pass_width * lerp(1.0, stride, i / passes);
			texel_h = 1.0 / pass_height * lerp(1.0, stride, i / passes);
			uniform_set("u_vTexelSize", shader_set_uniform_f, [texel_w, texel_h]);
			
			draw_surface(active_index ? surface_a : surface_b, 0, 0);
			surface_reset_target();
			active_index = not active_index;
		}
		shader_reset();
		
		surface_set_target(surface_out); 
		// Draw current swap to surface:
		draw_primitive_begin_texture(pr_trianglestrip, gbuffer[$ CAMERA_GBUFFER.final]);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(buffer_width, 0, 1, 0);
		draw_vertex_texture(0, buffer_height, 0, 1);
		draw_vertex_texture(buffer_width, buffer_height, 1, 1);
		draw_primitive_end();
		
		gpu_set_blendmode(bm_add);
		// Add bloom on top:
		draw_primitive_begin_texture(pr_trianglestrip, surface_get_texture(active_index ? surface_a : surface_b));
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(buffer_width, 0, 1, 0);
		draw_vertex_texture(0, buffer_height, 0, 1);
		draw_vertex_texture(buffer_width, buffer_height, 1, 1);
		draw_primitive_end();
		
		surface_reset_target();
		gpu_set_blendmode(bm_normal);
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		if (surface_exists(surface_a)){
			surface_free(surface_a);
			surface_a = -1;
		}
		if (surface_exists(surface_b)){
			surface_free(surface_b);
			surface_b = -1;
		}
	}
	#endregion
}