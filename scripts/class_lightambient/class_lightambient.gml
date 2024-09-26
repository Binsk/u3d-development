/// ABOUT
/// An ambient light is the simplest of lights and will simply apply its 
/// lighting to everything in the scene equally.

/// @stub	Look into https://computergraphics.stackexchange.com/questions/3955/physically-based-shading-ambient-indirect-lighting
///			for improved ambient lighting effects.
function LightAmbient() : Light() constructor {
	#region PROPERTIES
	shader_lighting = shd_lighting_ambient;
	is_ambient_occlusion = false; // Only applies to opaque instances
	albedo = c_white;
	intensity = 1.0;
	
	uniform_sampler_albedo = -1;
	uniform_sampler_depth = -1;
	uniform_translucency = -1;
	uniform_albedo = -1;
	uniform_intensity = -1;
	#endregion
	
	#region METHODS
	/// @desc	Enables / Disables ambient occlusion for this light.
	function set_ambient_occlusion(enabled=false){
		is_ambient_occlusion = bool(enabled);
	}
	
	/// @desc	Set the lighting intensity which multplies against the light's
	///			color in the shader.
	function set_intensity(intensity=1.0){
		self.intensity = max(0, intensity);
	}
	
	function render_shadows(gbuffer=[], body_array=[]){
		if (not is_ambient_occlusion)
			return;
		
/// @stub	Implement ambient occlusion render + blurring
	}
	
	function apply_gbuffer(gbuffer, is_translucent=false){
		if (uniform_sampler_albedo < 0)
			uniform_sampler_albedo = shader_get_sampler_index(shader_lighting, "u_sAlbedo");
		
		if (uniform_sampler_depth < 0)
			uniform_sampler_depth = shader_get_sampler_index(shader_lighting, "u_sDepth");
		
		if (uniform_translucency < 0)
			uniform_translucency = shader_get_uniform(shader_lighting, "u_iTranslucency");
		
		if (uniform_intensity < 0)
			uniform_intensity = shader_get_uniform(shader_lighting, "u_fIntensity");
		
		if (uniform_albedo < 0)
			uniform_albedo = shader_get_uniform(shader_lighting, "u_vAlbedo");
		
		texture_set_stage(uniform_sampler_albedo, gbuffer[$ is_translucent ? CAMERA_GBUFFER.albedo_opaque : CAMERA_GBUFFER.albedo_opaque]);
		if (not is_translucent)
			texture_set_stage(uniform_sampler_depth, gbuffer[$ is_translucent ? CAMERA_GBUFFER.depth_opaque : CAMERA_GBUFFER.depth_opaque]);
		
		shader_set_uniform_i(uniform_translucency, is_translucent);
	}
	
	function apply(){
		shader_set_uniform_f(uniform_albedo, color_get_red(albedo) / 255, color_get_green(albedo) / 255, color_get_blue(albedo) / 255);
		shader_set_uniform_f(uniform_intensity, intensity);
	}
	
	super.mark("free");
	function free(){
		super.execute("free");
		
/// @stub	Free SSAO surface
	}
	#endregion
}