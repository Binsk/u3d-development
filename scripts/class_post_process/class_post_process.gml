/// @about
///	A PostProcessFX is a post-processing shader that can be attached to a camera
///	to apply a screen-space effect before the final tonemap is applied and the
/// result rendered out.
///
/// The PostProcessFX will be provide an 'out' surface and a subset of the
///	camera's GBuffer textures. Take note of the uniform variables to understand how
///	your shader can access them. Any undefined uniforms will simply not be sent to
/// your shader.
///
/// The input and output textures are in the rgba16float format with colors in
/// linear space. While a large number of PPFX can simply be created by using this
/// base class some more complicated effects may need to create a child class.

#region AVAILABLE UNIFORMS
// The following are the uniforms that are available to your PPFX shader. If a uniform is
// not specified in your shader then it will not be sent.
// Note that dead textures may be passed in if a specific stage is disabled by the camera!
//	UNIFORM					TYPE			DESCRIPTION
// u_sInput				(sampler2D)		final combined render of all passes including PPFX up to this point
// u_sFinalOpaque		(sampler2D)		final output of opaque pass 
// u_sFinalTranslucent	(sampler2D)		final output of translucent pass 
// u_sDepthOpaque		(sampler2D)		original depth buffer of opaque pass
// u_sDepthTranslucent	(sampler2D)		original depth buffer of translucent pass
// u_vTexelSize			(vec2)			texel size of all provided textures
#endregion

function PostProcessFX(shader) : U3DObject() constructor {
	#region PROPERTIES
	self.shader = shader;
	is_enabled = true;
	#endregion
	
	#region METHODS
	function set_enabled(enabled){
		is_enabled = bool(enabled);
	}
	
	/// @desc	The function that is called when processing the post-processing effect.
	/// @param	{surface}	surface_out		the surface to render the final result to
	function render(surface_out){
		if (not is_enabled)
			return;
			
		var buffer_width = Camera.ACTIVE_INSTANCE.buffer_width;
		var buffer_height = Camera.ACTIVE_INSTANCE.buffer_height;
		var gbuffer = Camera.ACTIVE_INSTANCE.gbuffer.textures;
		
		surface_set_target(surface_out);
		if (shader_current() != shader)
			shader_set(shader);
			
		sampler_set("u_sInput", gbuffer[$ CAMERA_GBUFFER.final] ?? -1);
		sampler_set("u_sFinalOpaque", gbuffer[$ CAMERA_GBUFFER.light_opaque] ?? -1);
		sampler_set("u_sFinalTranslucent", gbuffer[$ CAMERA_GBUFFER.light_translucent] ?? -1);
		sampler_set("u_sDepthOpaque", gbuffer[$ CAMERA_GBUFFER.depth_opaque] ?? -1);
		sampler_set("u_sDepthTranslucent", gbuffer[$ CAMERA_GBUFFER.depth_translucent] ?? -1);
		uniform_set("u_vTexelSize", shader_set_uniform_f, [texture_get_texel_width(surface_get_texture(surface_out)), texture_get_texel_height(surface_get_texture(surface_out))]);
			
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(buffer_width, 0, 1, 0);
		draw_vertex_texture(0, buffer_height, 0, 1);
		draw_vertex_texture(buffer_width, buffer_height, 1, 1);
		draw_primitive_end();
			
		shader_reset();
		surface_reset_target();
	}
	#endregion
	
	#region INIT
	if (not shader_is_compiled(shader))
		throw new Exception("failed to generate PostProcessFX! Invalid shader.");
	#endregion
}