/// @about
/// A 3D camera that handles rendering for a specific view in 3D space.
/// Can assume to look down the x+ axis w/ a y+up value

/// @desc	Defines the necessary buffers we will need for the graphics pipeline
///			for this camera. We use separate albedo/depth pairs simply for the
///			depth buffer.
///			Any buffer that DOESN'T have an explicit *_opaque/*_translucent will be
///			re-used across stages.
enum CAMERA_GBUFFER {
	albedo_opaque,			// Albedo color (rgba8unorm)
	albedo_translucent,
	depth_opaque,			// Depth map; taken from albedo
	depth_translucent,	
	
	normal,					// Normal map (rgba8unorm)
	view,					// View vector map (rgba8unorm) in world-space
	emissive,				// Emmisive map (rgba8unorm)
	pbr,					// PBR properties (rgba8unorm); R: specular, G: roughness, B: metal
	
	out_opaque,				// Out surface (rgba16float) of lighting pass
	out_translucent
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
	none,
}

/// @desc	Creates a new 3D camera that can be moved around the world and added
///			to the rendering pipeline.
function Camera(znear=0.01, zfar=1024.0, fov=45) : Node() constructor{
	#region PROPERTIES
	static DISPLAY_WIDTH = undefined; // Full display size to measure anchor points
	static DISPLAY_HEIGHT = undefined;
	
	anchor = new CameraAnchor(self);
	tonemap = CAMERA_TONEMAP.none;
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
	
	render_stages = CAMERA_RENDER_STAGE.both;	// Which render stages will be rendered
	
	#region SHADER UNIFORMS
	uniform_sampler_opaque = -1;
	uniform_sampler_translucent = -1;
	uniform_sampler_dopaque = -1;
	uniform_sampler_dtranslucent = -1;
	uniform_render_stages = -1;
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
		var forward = get_forward_vector();
		var up = get_up_vector();
		var to = vec_add_vec(position, forward);
		return matrix_build_lookat(position.x, position.y, position.z, to.x, to.y, to.z, up.x, up.y, up.z);
	}
	
	/// @desc	Build the projection matrix required for this camera.
	function get_projection_matrix(){
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
		
		return matrix;
	}
	
	function set_znear(znear){
		self.znear = znear;
	}
	
	function set_zfar(zfar){
		self.zfar = zfar;
	}
	
	function set_fow(fow){
		self.fow = fow;
	}
	
	function set_tonemap(tonemap){
		if (tonemap == self.tonemap)
			return;
		
		// If switching to/from HDR we need to create new surface types
		if (sign(tonemap) != sign(tonemap)){
			if (surface_exists(surfaces[$ CAMERA_GBUFFER.out_opaque]))
				surface_free(surfaces[$ CAMERA_GBUFFER.out_opaque]);
			
			if (surface_exists(surfaces[$ CAMERA_GBUFFER.out_translucent]))
				surface_free(surfaces[$ CAMERA_GBUFFER.out_translucent]);
		}
		
		self.tonemap = tonemap;
	}
	
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
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.out_opaque])){
			if (render_stages & CAMERA_RENDER_STAGE.opaque){
				surfaces[$ CAMERA_GBUFFER.out_opaque] = surface_create(buffer_width, buffer_height, surface_rgba16float);
				textures[$ CAMERA_GBUFFER.out_opaque] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.out_opaque]);
			}
		}
		else if (render_stages & CAMERA_RENDER_STAGE.opaque <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.out_opaque])
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.out_translucent])){
			if (render_stages & CAMERA_RENDER_STAGE.translucent){
				surfaces[$ CAMERA_GBUFFER.out_translucent] = surface_create(buffer_width, buffer_height, surface_rgba16float);
				textures[$ CAMERA_GBUFFER.out_translucent] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.out_translucent]);
			}
		}
		else if (render_stages & CAMERA_RENDER_STAGE.translucent <= 0)
			surface_free(surfaces[$ CAMERA_GBUFFER.out_translucent])
		
		surface_depth_disable(false);
		
		// Check for resizing:
		if (render_stages & CAMERA_RENDER_STAGE.opaque){
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.albedo_opaque], buffer_width, buffer_height);
			
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.out_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.out_opaque]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.out_opaque], buffer_width, buffer_height);
		}
		
		if (render_stages & CAMERA_RENDER_STAGE.translucent){
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo_translucent]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.out_translucent]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.albedo_translucent], buffer_width, buffer_height);
			
			if (surface_get_width(surfaces[$ CAMERA_GBUFFER.out_translucent]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.out_translucent]) != buffer_height)
				surface_resize(surfaces[$ CAMERA_GBUFFER.out_translucent], buffer_width, buffer_height);
		}
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.normal], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.view]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.view]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.view], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.pbr], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.emissive]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.emissive]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.emissive], buffer_width, buffer_height);
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
		shader_set_uniform_matrix_array(shader_get_uniform(shd_view_buffer, "u_mInvProj"), matrix_get_inverse(get_projection_matrix()));
		shader_set_uniform_matrix_array(shader_get_uniform(shd_view_buffer, "u_mInvView"), matrix_get_inverse(get_view_matrix()));
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
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.out_opaque + is_translucent]);
		draw_clear_alpha(c_black, 0.0);
		gpu_set_blendmode(bm_add);
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
			
			light.apply();
			draw_primitive_begin_texture(pr_trianglestrip, -1);
			draw_vertex_texture(0, 0, 0, 0);
			draw_vertex_texture(buffer_width, 0, 1, 0);
			draw_vertex_texture(0, buffer_height, 0, 1);
			draw_vertex_texture(buffer_width, buffer_height, 1, 1);
			draw_primitive_end();
		}
		
		shader_reset();
		
		// Special render for emissive textures:
		static uniform_emissive = -1;
		if (uniform_emissive < 0)
			uniform_emissive = shader_get_sampler_index(shd_lighting_emissive, "u_sEmissive");
			
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
		
/// @stub	Implement; all the following is just for testing anti-aliasing
		// gpu_set_blendmode_ext(bm_one, bm_zero);
		// surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.out_translucent]);
		// draw_clear_alpha(0, 0);
		// shader_set(shd_fxaa);
		// shader_set_uniform_f(shader_get_uniform(shd_fxaa, "u_vTexsize"), buffer_width, buffer_height);
		// draw_surface(gbuffer.surfaces[$ CAMERA_GBUFFER.out_opaque], 0, 0);
		// shader_reset();
		// surface_reset_target();
	};
	
	/// @desc	Renders to the screen and converts back into sRGB
	function render_out(){
		if (render_stages <= 0)
			return;
		
		if (uniform_sampler_opaque < 0)
			uniform_sampler_opaque = shader_get_sampler_index(shd_finalize, "u_sFinalOpaque");
		if (uniform_sampler_translucent < 0)
			uniform_sampler_translucent = shader_get_sampler_index(shd_finalize, "u_sFinalTranslucent");
		if (uniform_sampler_dopaque < 0)
			uniform_sampler_dopaque = shader_get_sampler_index(shd_finalize, "u_sDepthOpaque");
		if (uniform_sampler_dtranslucent < 0)
			uniform_sampler_dtranslucent = shader_get_sampler_index(shd_finalize, "u_sDepthTranslucent");
		if (uniform_render_stages < 0)
			uniform_render_stages = shader_get_uniform(shd_finalize, "u_iRenderStages");

		var	tex_o = (render_stages & CAMERA_RENDER_STAGE.opaque ? gbuffer.textures[$ CAMERA_GBUFFER.out_opaque] : sprite_get_texture(spr_default_white, 0))
		var	tex_do = (render_stages & CAMERA_RENDER_STAGE.opaque ? gbuffer.textures[$ CAMERA_GBUFFER.depth_opaque] : sprite_get_texture(spr_default_white, 0))
		var	tex_t = (render_stages & CAMERA_RENDER_STAGE.translucent ? gbuffer.textures[$ CAMERA_GBUFFER.out_translucent] : sprite_get_texture(spr_default_white, 0))
		var	tex_dt = (render_stages & CAMERA_RENDER_STAGE.translucent ? gbuffer.textures[$ CAMERA_GBUFFER.depth_translucent] : sprite_get_texture(spr_default_white, 0))

		shader_set(shd_finalize);
		texture_set_stage(uniform_sampler_opaque, tex_o);
		texture_set_stage(uniform_sampler_translucent, tex_t);
		texture_set_stage(uniform_sampler_dopaque, tex_do);
		texture_set_stage(uniform_sampler_dtranslucent, tex_dt);
		shader_set_uniform_i(uniform_render_stages, render_stages);
		
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
	#endregion
}