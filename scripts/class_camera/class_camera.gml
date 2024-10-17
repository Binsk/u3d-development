/// @about
/// A 3D camera that handles rendering for a specific view in 3D space.
/// Can assume to look down the x+ axis w/ a y+up value

/// @desc	Defines the necessary buffers we will need for the graphics pipeline
///			for this camera. We use separate albedo/depth pairs simply for the
///			depth buffer.
///			Any buffer that DOESN'T have an explicit *_opaque/*_translucent will be
///			re-used across stages.
///			Some buffers are not allocated if they are not used.
enum CAMERA_GBUFFER {
	albedo_opaque,			// Albedo color (rgba8unorm)
	albedo_translucent,
	depth_opaque,			// Depth map; taken from albedo
	depth_translucent,	
	
	normal,					// Normal map (rgba8unorm)
	view,					// View vector map (rgba8unorm) in world-space
	emissive,				// Emmisive map (rgba8unorm)
	pbr,					// PBR properties (rgba8unorm); R: specular, G: roughness, B: metal
	
	light_opaque,			// Out surface (rgba16float) of lighting passes
	light_translucent,
	
	final,					// Final combined surface (rgba16float)
	post_process,			// Post-processing middle-man surface (rgba16float)
}

/// @desc	Used by materials to specify which render stage they should appear in.
enum CAMERA_RENDER_STAGE {
	none = 0,			// Does not render at all
	opaque = 1,			// Renders in the opaque pass (all alphas are 0 or 1)
	translucent = 2,	// Renders in the translucent pass (alpha can be [0..1])
	both = 3			// Renders in both stages (not usually desired)
}

/// @desc	defines the tonemapping to use for the camera; 'none' is a straight
///			render while every other option will enable HDR and 4x the vRAM usage
enum CAMERA_TONEMAP {
	none,	// Does nothing, lights may blow-out. Only use if a custom PPFX is used to handle gamma correction
	simple,	// Does a simple gamma correction w/o any special exposure calculations
}

/// @desc	Creates a new 3D camera that can be moved around the world and added
///			to the rendering pipeline.
function Camera(znear=0.01, zfar=1024.0, fov=45) : Node() constructor{
	#region PROPERTIES
	static DISPLAY_WIDTH = undefined; // Full display size to measure anchor points
	static DISPLAY_HEIGHT = undefined;
	
	anchor = new CameraAnchor(self);
	tonemap = CAMERA_TONEMAP.simple;
	buffer_width = undefined;
	buffer_height = undefined;
	custom_render_size = undefined;	// Overrides global DISPLAY_* size if set. ANCHOR WILL BE IGNORED!
	self.znear = znear;
	self.zfar = zfar;
	self.fov = fov;	// y-FOV
	gbuffer = {
		surfaces : {},
		textures : {}
	};
/// @stub	Add post-processing structure & addition / removal / render to camera
	post_process_effects = {};	// priority -> effect pairs for post processing effects
	
	render_stages = CAMERA_RENDER_STAGE.both;	// Which render stages will be rendered
	
	self.matrix_inv_view = undefined;
	self.matrix_inv_projection = undefined;
	self.matrix_view = undefined;
	self.matrix_projection = undefined;
	
	#region SHADER UNIFORMS
	uniform_sampler_opaque = -1;
	uniform_sampler_translucent = -1;
	uniform_sampler_dopaque = -1;
	uniform_sampler_dtranslucent = -1;
	uniform_render_stages = -1;
	
	uniform_sampler_texture = -1;
	uniform_tonemap = -1;
	#endregion
	
	#endregion
	
	#region METHODS
	
	/// @desc	If set, overrides the CamerAnchor and DISPLAY_WIDTH/HEIGHT values.
	///			Useful if rendering specifically for in-game surfaces and the like.
	function set_custom_render_size(width=undefined, height=undefined){
		if (is_undefined(width) or is_undefined(height)){
			custom_render_size = undefined;
			return;
		}
		custom_render_size = {
			x : max(1.0, width),
			y : max(1.0, height)
		}
	}
	
	/// @desc	Returns the amount of vRAM used by the gbuffer, in bytes, for this camera.
	function get_vram_usage(){
		var bytes = 0;
		bytes += (buffer_width * buffer_height) * (
			(render_stages & CAMERA_RENDER_STAGE.opaque ? 8 : 0) +		// opaque albedo + depth
			(render_stages & CAMERA_RENDER_STAGE.translucent ? 8 : 0) +	// translucent albedo + depth
			16 +  // Normal, view, emissive, pbr 
			(render_stages & CAMERA_RENDER_STAGE.opaque ? 8 : 0) +		// opaque output (16f)
			(render_stages & CAMERA_RENDER_STAGE.translucent ? 8 : 0) +	// translucent output (16f)
			16 // Final, post process
		);
		
		return bytes;
	}
	
	/// @desc	Set which render stages should be rendered. E.g., if you know there
	///			will be no translucent materials then you can save vRAM and CPU 
	///			performance by disabling the the translucent stage.
	function set_render_stages(stages=CAMERA_RENDER_STAGE.both){
		render_stages = clamp(floor(stages), 0, 3);
	}
	
	/// @desc	Returns the camera anchor attached to this camera.
	function get_anchor(){
		return anchor;
	}
	
	/// @desc	Build the view matrix required for this camera.
	function get_view_matrix(){
		if (not is_undefined(self.matrix_view))
			return self.matrix_view;
		
		var forward = get_forward_vector();
		var up = get_up_vector();
		var to = vec_add_vec(position, forward);
		self.matrix_view = matrix_build_lookat(position.x, position.y, position.z, to.x, to.y, to.z, up.x, up.y, up.z);
		
		return self.matrix_view;
	}
	
	function get_inverse_view_matrix(){
		if (not is_undefined(matrix_inv_view))
			return matrix_inv_view;
		
		matrix_inv_view = matrix_get_inverse(get_view_matrix());;
		return matrix_inv_view;
	}
	
	/// @desc	Build the projection matrix required for this camera.
	function get_projection_matrix(){
		if (not is_undefined(self.matrix_projection))
			return self.matrix_projection;
		
		if (is_undefined(buffer_width)) // Cannot determine render size
			return matrix_build_identity();

		var aspect = buffer_width / buffer_height;
		var yfov = 2.0 * arctan(dtan(fov/2) * aspect);
		
		var h = 1 / tan(yfov * 0.5);
		var w = h / aspect;
		var a = zfar / (zfar - znear);
		var b = (-znear * zfar) / (zfar - znear);
		var matrix = [
			w, 0, 0, 0,
			0, get_is_directx_pipeline() ? h : -h, 0, 0,
			0, 0, a, 1,
			0, 0, b, 0
		];
		
		self.matrix_projection = matrix;
		return matrix;
	}
	
	function get_inverse_projection_matrix(){
		if (not is_undefined(matrix_inv_projection))
			return matrix_inv_projection;
		
		matrix_inv_projection = matrix_get_inverse(get_projection_matrix());;
		return matrix_inv_projection;
	}
	
	function set_znear(znear){
		self.matrix_projection = undefined;
		matrix_inv_projection = undefined;
		self.znear = znear;
	}
	
	function set_zfar(zfar){
		self.matrix_projection = undefined;
		matrix_inv_projection = undefined;
		self.zfar = zfar;
	}
	
	function set_fow(fow){
		self.matrix_projection = undefined;
		matrix_inv_projection = undefined;
		self.fow = fow;
	}
	
	function set_tonemap(tonemap){
		if (tonemap == self.tonemap)
			return;

		self.tonemap = tonemap;
	}
	
	/// @dsec	Adds a new post processing effect with the specified render priority.
	///			Does NOT check for duplicates.
	function add_post_process_effect(effect, priority=0){
		if (not is_instanceof(effect, PostProcessFX))
			throw new Exception("invalid type, expected [PostProcessFX]!");
			
		priority = floor(real(priority));
		var array = (post_process_effects[$ priority] ?? []);
		array_push(array, effect);
		post_process_effects[$ priority] = array;
	}
	
/// @stub	Add removing a post-processing effect
	
	function generate_gbuffer(){
		if (is_undefined(Camera.DISPLAY_WIDTH))
			Camera.DISPLAY_WIDTH = window_get_width();
		if (is_undefined(Camera.DISPLAY_HEIGHT))
			Camera.DISPLAY_HEIGHT = window_get_height();
			
		/// @note	the depth texture doesn't have its own surface as it is
		///			taken from the depth buffer of the albedo surface
		if (is_undefined(custom_render_size)){
			var screen_width = Camera.DISPLAY_WIDTH;
			var screen_height = Camera.DISPLAY_HEIGHT;
			buffer_width = anchor.get_dx(screen_width);
			buffer_height = anchor.get_dy(screen_height);
		}
		else{
			buffer_width = custom_render_size.x;
			buffer_height = custom_render_size.y;
		}
		var surfaces = gbuffer.surfaces;
		var textures = gbuffer.textures;
		
		// Check for existence:
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.albedo_opaque])){
			if (render_stages & CAMERA_RENDER_STAGE.opaque){
				surface_depth_disable(false);
				surfaces[$ CAMERA_GBUFFER.albedo_opaque] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
				textures[$ CAMERA_GBUFFER.albedo_opaque] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.albedo_opaque]);
				textures[$ CAMERA_GBUFFER.depth_opaque] = surface_get_texture_depth(surfaces[$ CAMERA_GBUFFER.albedo_opaque]);
			}
		}
		else if (render_stages & CAMERA_RENDER_STAGE.opaque <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.albedo_opaque])
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.albedo_translucent])){
			if (render_stages & CAMERA_RENDER_STAGE.translucent){
				surface_depth_disable(false);
				surfaces[$ CAMERA_GBUFFER.albedo_translucent] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
				textures[$ CAMERA_GBUFFER.albedo_translucent] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.albedo_translucent]);
				textures[$ CAMERA_GBUFFER.depth_translucent] = surface_get_texture_depth(surfaces[$ CAMERA_GBUFFER.albedo_translucent]);
			}
		}
		else if (render_stages & CAMERA_RENDER_STAGE.translucent <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.albedo_translucent])
		
		surface_depth_disable(true);
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.normal])){
			surfaces[$ CAMERA_GBUFFER.normal] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.normal] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.normal]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.view])){
			surfaces[$ CAMERA_GBUFFER.view] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.view] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.view]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.pbr])){
			surfaces[$ CAMERA_GBUFFER.pbr] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.pbr] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.pbr]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.emissive])){
			surfaces[$ CAMERA_GBUFFER.emissive] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.emissive] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.emissive]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.light_opaque])){
			if (render_stages & CAMERA_RENDER_STAGE.opaque){
				surfaces[$ CAMERA_GBUFFER.light_opaque] = surface_create(buffer_width, buffer_height, surface_rgba16float);
				textures[$ CAMERA_GBUFFER.light_opaque] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.light_opaque]);
			}
		}
		else if (render_stages & CAMERA_RENDER_STAGE.opaque <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.light_opaque])
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.light_translucent])){
			if (render_stages & CAMERA_RENDER_STAGE.translucent){
				surfaces[$ CAMERA_GBUFFER.light_translucent] = surface_create(buffer_width, buffer_height, surface_rgba16float);
				textures[$ CAMERA_GBUFFER.light_translucent] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.light_translucent]);
			}
		}
		else if (render_stages & CAMERA_RENDER_STAGE.translucent <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.light_translucent])
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.final])){
			surfaces[$ CAMERA_GBUFFER.final] = surface_create(buffer_width, buffer_height, surface_rgba16float);
			textures[$ CAMERA_GBUFFER.final] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.final])
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.post_process])){
			if (struct_names_count(post_process_effects) > 0){
				surfaces[$ CAMERA_GBUFFER.post_process] = surface_create(buffer_width, buffer_height, surface_rgba16float);
				textures[$ CAMERA_GBUFFER.post_process] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.post_process]);
			}
		}
		else if (struct_names_count(post_process_effects) <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.post_process])
		
		surface_depth_disable(false);
		
		// Check for resizing:
		if (render_stages & CAMERA_RENDER_STAGE.opaque){
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.albedo_opaque], buffer_width, buffer_height);
			
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.light_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.light_opaque]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.light_opaque], buffer_width, buffer_height);
		}
		
		if (render_stages & CAMERA_RENDER_STAGE.translucent){
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo_translucent]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.light_translucent]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.albedo_translucent], buffer_width, buffer_height);
			
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.light_translucent]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.light_translucent]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.light_translucent], buffer_width, buffer_height);
		}
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.normal], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.view]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.view]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.view], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.pbr], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.emissive]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.emissive]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.emissive], buffer_width, buffer_height);
			
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.final]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.final]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.final], buffer_width, buffer_height);
		
		if (surface_exists(surfaces[$ CAMERA_GBUFFER.post_process])){
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.post_process]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.post_process]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.post_process], buffer_width, buffer_height);
		}
	}
	
	/// @desc	Given an array of renderable bodies, the camera will render them
	///			out to the GBuffer.
	function render_gbuffer(body_array=[], is_translucent=false){
		if (not is_translucent and (render_stages & CAMERA_RENDER_STAGE.opaque) <= 0)
			return;
		
		if (is_translucent and (render_stages & CAMERA_RENDER_STAGE.translucent) <= 0)
			return;
		
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		gpu_set_cullmode(cull_noculling);
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		gpu_set_texrepeat(true);
		
		// Render models w/ materials to primary buffer channels:
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque + is_translucent], 0, 0);
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.normal], 0);
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.pbr], 0, 0);
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.emissive], 0, 0);
		
		surface_set_target_ext(0, gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque + is_translucent]);
		surface_set_target_ext(1, gbuffer.surfaces[$ CAMERA_GBUFFER.normal]);
		surface_set_target_ext(2, gbuffer.surfaces[$ CAMERA_GBUFFER.pbr]);
		surface_set_target_ext(3, gbuffer.surfaces[$ CAMERA_GBUFFER.emissive]);
		
		var world_matrix = matrix_get(matrix_world); // Cache so we can reset for later stages
		matrix_set(matrix_view, get_view_matrix());
		matrix_set(matrix_projection, get_projection_matrix());
		for (var i = array_length(body_array) - 1; i >= 0; --i){
			var body = body_array[i];
			if (body.get_render_layers() & get_render_layers() == 0) // This camera doesn't render this body
				continue;
				
			// Make sure model is renderable for this camera
			if (is_undefined(body.model_instance))
				continue;
			
			matrix_set(matrix_world, body.get_model_matrix());
			body.model_instance.render(self, is_translucent ? CAMERA_RENDER_STAGE.translucent : CAMERA_RENDER_STAGE.opaque);
		}
		matrix_set(matrix_world, world_matrix);
		surface_reset_target();
		
		// Render view vector buffer for use with lighting
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.view]);
		draw_clear(0);
		shader_set(shd_view_buffer);
		texture_set_stage(shader_get_sampler_index(shd_view_buffer, "u_sDepth"), gbuffer.textures[$ CAMERA_GBUFFER.depth_opaque + is_translucent]);
		shader_set_uniform_matrix_array(shader_get_uniform(shd_view_buffer, "u_mInvProj"), get_inverse_projection_matrix());
		shader_set_uniform_matrix_array(shader_get_uniform(shd_view_buffer, "u_mInvView"), get_inverse_view_matrix());
		shader_set_uniform_f(shader_get_uniform(shd_view_buffer, "u_vCamPosition"), position.x, position.y, position.z);
		
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(buffer_width, 0, 1, 0);
		draw_vertex_texture(0, buffer_height, 0, 1);
		draw_vertex_texture(buffer_width, buffer_height, 1, 1);
		draw_primitive_end();
		shader_reset();
		surface_reset_target();
	}
	
	function render_lighting(light_array=[], body_array=[], is_translucent=false){
		if (not is_translucent and (render_stages & CAMERA_RENDER_STAGE.opaque) <= 0)
			return;
		
		if (is_translucent and (render_stages & CAMERA_RENDER_STAGE.translucent) <= 0)
			return;
			
		// Render light shadows:
		if (not is_translucent){ // We only do so for opaque instances
			for (var i = array_length(light_array) - 1; i >= 0; --i){
				if (light_array[i].get_render_layers() & get_render_layers() == 0) // This light is not on the camera's render layer
					continue;
				
				if (not light_array[i].casts_shadows) // Light must have shadows enabled
					continue;
				
				light_array[i].render_shadows(gbuffer.textures, body_array, self);
			}
		}
		
/// @todo	Batch light types together (a shader for each) and pass in multiple
///			lights into the shader
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.light_opaque + is_translucent], c_black, 0.0);
		// gpu_set_blendmode(bm_add);
		for (var i = array_length(light_array) - 1; i >= 0; --i){
			var light = light_array[i];
			
			if (light.get_render_layers() & get_render_layers() == 0) // This light is not on the camera's render layer
				continue;
			
			if (is_undefined(light.get_shader())) // Invalid light
				continue;

			if (shader_current() != light.get_shader()){
				shader_set(light.get_shader());
				light.apply_gbuffer(gbuffer.textures, self, is_translucent);
			}
			gpu_set_blendmode_ext(bm_one, bm_zero);
			surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.final], 0, 0);
			surface_set_target_ext(0, gbuffer.surfaces[$ CAMERA_GBUFFER.final]); // Repurposed to avoid needing an extra buffer
			light.apply();
			draw_primitive_begin_texture(pr_trianglestrip, -1);
			draw_vertex_texture(0, 0, 0, 0);
			draw_vertex_texture(buffer_width, 0, 1, 0);
			draw_vertex_texture(0, buffer_height, 0, 1);
			draw_vertex_texture(buffer_width, buffer_height, 1, 1);
			draw_primitive_end();
			shader_reset();
			surface_reset_target();
			
			gpu_set_blendmode(bm_add);
			if (is_translucent or not light.apply_shadows(gbuffer.surfaces[$ CAMERA_GBUFFER.final], gbuffer.surfaces[$ CAMERA_GBUFFER.light_opaque + is_translucent])){
				surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.light_opaque + is_translucent]);
				draw_surface(gbuffer.surfaces[$ CAMERA_GBUFFER.final], 0, 0);
				surface_reset_target();
			}
			gpu_set_blendmode(bm_normal);
		}
		
		// Special render for emissive textures:
		static uniform_emissive = -1;
		if (uniform_emissive < 0)
			uniform_emissive = shader_get_sampler_index(shd_lighting_emissive, "u_sEmissive");
			
		gpu_set_blendmode(bm_add);
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.light_opaque + is_translucent]);
		shader_set(shd_lighting_emissive);
		texture_set_stage(uniform_emissive, gbuffer.textures[$ CAMERA_GBUFFER.emissive]);
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(buffer_width, 0, 1, 0);
		draw_vertex_texture(0, buffer_height, 0, 1);
		draw_vertex_texture(buffer_width, buffer_height, 1, 1);
		draw_primitive_end();
		shader_reset();
		
		gpu_set_blendmode(bm_normal);
		surface_reset_target();
	}
	
	function render_post_processing(){
		if (render_stages <= 0)
			return;
		
		// Since we are performing final post-process, go ahead and merge layers together:
		if (uniform_sampler_opaque < 0)
			uniform_sampler_opaque = shader_get_sampler_index(shd_combine_stages, "u_sFinalOpaque");
		if (uniform_sampler_translucent < 0)
			uniform_sampler_translucent = shader_get_sampler_index(shd_combine_stages, "u_sFinalTranslucent");
		if (uniform_sampler_dopaque < 0)
			uniform_sampler_dopaque = shader_get_sampler_index(shd_combine_stages, "u_sDepthOpaque");
		if (uniform_sampler_dtranslucent < 0)
			uniform_sampler_dtranslucent = shader_get_sampler_index(shd_combine_stages, "u_sDepthTranslucent");
		if (uniform_render_stages < 0)
			uniform_render_stages = shader_get_uniform(shd_combine_stages, "u_iRenderStages");

		var	tex_o = (render_stages & CAMERA_RENDER_STAGE.opaque ? gbuffer.textures[$ CAMERA_GBUFFER.light_opaque] : sprite_get_texture(spr_default_white, 0))
		var	tex_do = (render_stages & CAMERA_RENDER_STAGE.opaque ? gbuffer.textures[$ CAMERA_GBUFFER.depth_opaque] : sprite_get_texture(spr_default_white, 0))
		var	tex_t = (render_stages & CAMERA_RENDER_STAGE.translucent ? gbuffer.textures[$ CAMERA_GBUFFER.light_translucent] : sprite_get_texture(spr_default_white, 0))
		var	tex_dt = (render_stages & CAMERA_RENDER_STAGE.translucent ? gbuffer.textures[$ CAMERA_GBUFFER.depth_translucent] : sprite_get_texture(spr_default_white, 0))

		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.final]);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		draw_clear_alpha(0, 0);
		shader_set(shd_combine_stages);
		texture_set_stage(uniform_sampler_opaque, tex_o);
		texture_set_stage(uniform_sampler_translucent, tex_t);
		texture_set_stage(uniform_sampler_dopaque, tex_do);
		texture_set_stage(uniform_sampler_dtranslucent, tex_dt);
		shader_set_uniform_i(uniform_render_stages, render_stages);
		
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(buffer_width, 0, 1, 0);
		draw_vertex_texture(0, buffer_height, 0, 1);
		draw_vertex_texture(buffer_width, buffer_height, 1, 1);
		draw_primitive_end();
		
		gpu_set_blendmode(bm_normal);
		shader_reset();
		surface_reset_target();
		
		if (struct_names_count(post_process_effects) <= 0)
			return;
		
		var priority = ds_priority_create();
		var keys = struct_get_names(post_process_effects);
		for (var i = array_length(keys) - 1; i >= 0; --i){
			var values = post_process_effects[$ keys[i]];
			for (var j = 0; j < array_length(values); ++j)
				ds_priority_add(priority, values[j], keys[i]);
		}
		
		gpu_set_blendmode_ext(bm_one, bm_zero);
		while (not ds_priority_empty(priority)){
			var data = ds_priority_delete_max(priority);
			data.render(gbuffer.surfaces[$ CAMERA_GBUFFER.post_process], gbuffer.textures, buffer_width, buffer_height);

			// Swap surfaces / textures since the modified data will have been
			// applied to post_process
			var fs = gbuffer.surfaces[$ CAMERA_GBUFFER.final];
			var ft = gbuffer.textures[$ CAMERA_GBUFFER.final];
			gbuffer.surfaces[$ CAMERA_GBUFFER.final] = gbuffer.surfaces[$ CAMERA_GBUFFER.post_process];
			gbuffer.textures[$ CAMERA_GBUFFER.final] = gbuffer.textures[$ CAMERA_GBUFFER.post_process];
			gbuffer.surfaces[$ CAMERA_GBUFFER.post_process] = fs;
			gbuffer.textures[$ CAMERA_GBUFFER.post_process] = ft;
		}
		gpu_set_blendmode(bm_normal);
		ds_priority_destroy(priority);
	};
	
	/// @desc	Renders to the screen w/ tonemapping
	function render_out(){
		if (render_stages <= 0)
			return;
		
		if (uniform_sampler_texture < 0)
			uniform_sampler_texture = shader_get_sampler_index(shd_tonemap, "u_sTexture");
		
		if (uniform_tonemap < 0)
			uniform_tonemap = shader_get_uniform(shd_tonemap, "u_iTonemap");
		
		shader_set(shd_tonemap);
		texture_set_stage(uniform_sampler_texture, gbuffer.textures[$ CAMERA_GBUFFER.final]);
		shader_set_uniform_i(uniform_tonemap, tonemap);
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(anchor.get_x(buffer_width), anchor.get_y(buffer_height), 1, 0);
		draw_vertex_texture(anchor.get_x(buffer_width) + anchor.get_dx(buffer_width), anchor.get_y(buffer_height), 0, 0);
		draw_vertex_texture(anchor.get_x(buffer_width), anchor.get_y(buffer_height) + anchor.get_dx(buffer_height), 1, 1);
		draw_vertex_texture(anchor.get_x(buffer_width) + anchor.get_dx(buffer_width), anchor.get_y(buffer_height) + anchor.get_dy(buffer_height), 0, 1);
		draw_primitive_end();
		shader_reset();
	}
	super.register("free");
	function free(){
		super.execute("free");
		
		var surfaces = gbuffer.surfaces;
		var keys = struct_get_names(surfaces);
		for (var i = array_length(keys) - 1; i >= 0; --i){
			if (surface_exists(surfaces[$ keys[i]]))
				surface_free(surfaces[$ keys[i]]);
		}
		gbuffer = {surfaces:{}, textures:{}};
		
		delete anchor;
		anchor = undefined;
	}
	#endregion
	
	#region INIT
	var reset_matrix = new Callable(self, function(){self.matrix_view = undefined; self.matrix_inv_view = undefined;});
	signaler.add_signal("set_rotation", reset_matrix);
	signaler.add_signal("set_position", reset_matrix);
	#endregion
}