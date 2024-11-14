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
/// linear space.

/// @todo	Update this class, it needs a lot of love. Way too janky, needs to be more robust.
function PostProcessFX(shader) : U3DObject() constructor {
	#region PROPERTIES
	self.shader = shader;
	is_enabled = true;
	
	uniform_sampler_input = -1;				// u_sInput				(sampler2D)		finalized input texture to pull from
	uniform_texel_size = -1;				// u_vTexelSize			(vec2)			texel size for the input sampler
/// @stub	Add support for more GBuffer textures
	#endregion
	
	#region METHODS
	function set_enabled(enabled){
		is_enabled = bool(enabled);
	}
	
	function render(surface_out, gbuffer, buffer_width, buffer_height){
		if (not is_enabled)
			return;
			
/// @todo	Add more samplers and uniforms to this
		if (uniform_sampler_input < 0)
			uniform_sampler_input = shader_get_sampler_index(shader, "u_sInput");
		
		if (uniform_texel_size < 0)
			uniform_texel_size = shader_get_uniform(shader, "u_vTexelSize");
		
		surface_set_target(surface_out);
		if (shader_current() != shader)
			shader_set(shader);
			
		if (uniform_sampler_input >= 0)
			texture_set_stage(uniform_sampler_input, gbuffer[$ CAMERA_GBUFFER.final]);
		
		if (uniform_texel_size >= 0)
			shader_set_uniform_f(uniform_texel_size, texture_get_texel_width(surface_get_texture(surface_out)), texture_get_texel_height(surface_get_texture(surface_out)));
			
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