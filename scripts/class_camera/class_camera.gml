/// @about
/// A 3D camera defines the position and render details for a view into the scene.
///	There are different kinds of cameras that can be used but the most common is
///	the CameraView(), which will render straight to the screen. The Camera() class
///	is a template class and should be inherited, not used directly.

/// @desc	Defines the necessary buffers we will need for the graphics pipeline
///			for this camera. We use separate albedo/depth pairs simply for the
///			depth buffer.
///			Any buffer that DOESN'T have an explicit *_opaque/*_translucent will be
///			re-used across stages.
///			Some buffers are not allocated if they are not used.
enum CAMERA_GBUFFER {
	albedo_opaque,			// Albedo color (rgba8unorm)
	albedo_translucent,
	depth_opaque,			// Depth map; texture taken from albedo
	depth_translucent,	
	
	normal,					// Normal map (rgba8unorm)
	view,					// View vector map (rgba8unorm) in world-space
	emissive,				// Emissive map (rgba8unorm)
	pbr,					// PBR properties (rgba8unorm); G: roughness, B: metal
	
	light_opaque,			// Out surface (rgba16float) of lighting passes
	light_translucent,
	
	final,					// Final combined surface before tonemapping (rgba16float)
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

function Camera() : Node() constructor {
	#region PROPERTIES
	buffer_width = undefined;	// Render resolution
	buffer_height = undefined;
	gbuffer = {
		surfaces : {}, // GBuffer surfaces with IDs from CAMERA_GBUFFER
		textures : {}  // Gbuffer textures, in some cases they do NOT have an equivalent surface!
	};
	render_stages = CAMERA_RENDER_STAGE.both; // Which render stages to perform
	render_tonemap = CAMERA_TONEMAP.none;
	/// @stub	Add post-processing structure & addition / removal / render to camera
	post_process_effects = {};	// priority -> effect pairs for post processing effects
	
	#region SHADER UNIFORMS
	uniform_sampler_opaque = -1;
	uniform_sampler_translucent = -1;
	uniform_sampler_dopaque = -1;
	uniform_sampler_dtranslucent = -1;
	uniform_render_stages = -1;
	#endregion
	#endregion
	
	#region METHODS
	/// @desc	Return an array of all attached Eye() instances.
	function get_eye_array(){
		return [];
	}
	
	/// @desc	Set which render stages should be rendered. Even when no instances
	///			exist in a render stage, that stage still takes up processing time
	///			and vRAM. E.g., if you KNOW you will never have translucent materials
	///			then disabling the translucent stage will free up vRAM and give you
	///			some extra FPS.
	function set_render_stages(stages=CAMERA_RENDER_STAGE.both){
		render_stages = clamp(floor(stages), 0, 3);
	}
	
	function set_znear(znear){
		var eye_array = get_eye_array();
		for (var i = array_length(eye_array) - 1; i >= 0; --i)
			eye_array[i].set_znear(znear);
	}
	
	function set_zfar(zfar){
		var eye_array = get_eye_array();
		for (var i = array_length(eye_array) - 1; i >= 0; --i)
			eye_array[i].set_zfar(zfar);
	}
	
	function set_fow(fow){
		var eye_array = get_eye_array();
		for (var i = array_length(eye_array) - 1; i >= 0; --i)
			eye_array[i].set_fow(fow);
	}
	
	/// @desc	Sets the render size for the camera, in pixels. This size will
	///			be used by each eye maintained by the camera.
	function set_render_size(width, height){
		buffer_width = max(1, floor(real(width)));
		buffer_height = max(1, floor(real(height)));
	}
	
	/// @desc	Sets the tonemap to use when converting the final linearized 
	///			color buffer to the rgba8 channels to display to the screen.
	function set_tonemap(tonemap){
		self.render_tonemap = tonemap;
	}
	
	/// @desc	Returns the estimated amount of vRAM used by the gbuffer, in bytes, for this camera.
	///			Does NOT account for body materials or light buffers.
	function get_vram_usage(){
		if (is_undefined(buffer_width) or is_undefined(buffer_height))
			return 0;
			
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
	
	/// @desc	Auto-calculates a new render size (if applicable). The render size
	///			is applied equally for every eye in the camera.
	function update_render_size(){};
	
	/// @desc	Generate/Resize all the necessary render buffers.
	function generate_gbuffer(){
		if (is_undefined(buffer_width) or is_undefined(buffer_height))
			throw new Exception("failed to render; buffer size undefined!");
			
		var surfaces = gbuffer.surfaces;
		var textures = gbuffer.textures;
		
		// Clear surfaces that had size changes; we clear instead of resize as the
		// resize doesn't seem to keep the surface format correctly.
		var surface_keys = struct_get_names(surfaces);
		for (var i = array_length(surface_keys) - 1; i >= 0; --i){
			var surface = surfaces[$ surface_keys[i]];
			if (not surface_exists(surface))
				continue;
			
			if (surface_get_width(surface) == buffer_width and surface_get_height(surface) == buffer_height)
				continue;
			
			surface_free(surface);
			struct_remove(surfaces, surface_keys[i]);
		}
		
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
	}
	
	/// @desc	Given an array of renderable bodies, the camera will render all the
	///			texture data into the GBuffer to later be passed into the lighting
	///			stage.
	function render_gbuffer(eye, body_array=[], is_translucent=false){
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
		matrix_set(matrix_view, eye.get_view_matrix());
		matrix_set(matrix_projection, eye.get_projection_matrix());
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
		shader_set_uniform_matrix_array(shader_get_uniform(shd_view_buffer, "u_mInvProj"), eye.get_inverse_projection_matrix());
		shader_set_uniform_matrix_array(shader_get_uniform(shd_view_buffer, "u_mInvView"), eye.get_inverse_view_matrix());
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
	
	/// @desc	Renders all the shadows and lights, including emissive tetures, and adds
	///			them together on the final light surface.
	function render_lighting(eye, light_array=[], body_array=[], is_translucent=false){
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
				
				light_array[i].render_shadows(eye, body_array);
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

			shader_set(light.get_shader());
			gpu_set_blendmode_ext(bm_one, bm_zero);
			surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.final], 0, 0);
			surface_set_target_ext(0, gbuffer.surfaces[$ CAMERA_GBUFFER.final]); // Repurposed to avoid needing an extra buffer
/// @stub	Optimize having to re-apply the gbuffer for every light. This is due to the deferred shadow pass.
			light.apply_gbuffer(self, is_translucent);
			light.apply();
			draw_primitive_begin_texture(pr_trianglestrip, -1);
			draw_vertex_texture(0, 0, 0, 0);
			draw_vertex_texture(buffer_width, 0, 1, 0);
			draw_vertex_texture(0, buffer_height, 0, 1);
			draw_vertex_texture(buffer_width, buffer_height, 1, 1);
			draw_primitive_end();
			shader_reset();
			surface_reset_target();
			
			var applied_shadows = false;
			if (not is_translucent)
				applied_shadows = light.apply_shadows(eye, gbuffer.surfaces[$ CAMERA_GBUFFER.final], gbuffer.surfaces[$ CAMERA_GBUFFER.light_opaque + is_translucent]);
			
			if (not applied_shadows){
				gpu_set_blendmode(bm_add);
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
	
	/// @desc	Renders all the PostProcessFX added to the camera in order of priority.
	///			Executes on the current GBuffer state.
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
			if (not data.is_enabled)
				continue;
				
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
	
	/// @desc	Performs a complete render of an eye of the camera
	/// @param	{Eye}	eye					the eye structure to render
	/// @param	{array}	body_array=[]		the array of renderable bodies to process
	function render_eye(eye, body_array=[], light_array=[]){
		if (not is_instanceof(eye, Eye))
			throw new Exception("invalid type, expected [Eye]!");
		
		if (not U3DObject.are_equal(eye.get_camera(), self))
			throw new Exception("eye does not belong to rendering camera!");
		
		// Make sure the GBuffer exists and is valid
		generate_gbuffer();
		
		/// @note	Translucent is done first so the left-over shared buffers (such
		///			as normals) contain the opaque pass for post-processing. This is
		///			done because opaque is significantly more common.
		// Translucent pass:
		render_gbuffer(eye, body_array, true);
		render_lighting(eye, light_array, body_array, true);
		
		// Opaque pass:
		render_gbuffer(eye, body_array, false);
		render_lighting(eye, light_array, body_array, false);
		
		// Post-processing:
		render_post_processing();
	}
	
	/// @desc	Should execute a render_eye for every eye and combine results
	///			as necessary.
	function render(body_array, light_array){};
	
	/// @desc	Should push the final result to the final render destination; 
	///			whether that be the monitor, a VR headset, or a custom textured
	///			surface.
	function render_out(){};
	#endregion
}