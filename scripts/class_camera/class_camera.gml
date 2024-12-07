/// @about
/// A 3D camera defines the position and render details for a view into the scene.
///	There are different kinds of cameras that can be used but the most common is
///	the CameraView(), which will render straight to the screen. The Camera() class
///	is a template class and should be inherited, not used directly.

/// @todo	Add orthographic Eye / rendering

/// @desc	Defines the necessary buffers we will need for the graphics pipeline
///			for this camera. We use separate albedo/depth pairs simply for the
///			depth buffer.
///			Any buffer that DOESN'T have an explicit *_opaque/*_translucent will be
///			re-used across stages.
///			Some buffers are not allocated if they are not used.
enum CAMERA_GBUFFER {
	albedo,					// Albedo color (rgba8unorm)
	depth,					// Depth map; texture taken from albedo
	
	normal,					// Normal map (rgba8unorm)
	emissive,				// Emissive map (rgba8unorm)
	pbr,					// PBR properties (rgba8unorm); G: roughness, B: metal
	view,					// View vector map (rgba16float) in world-space
	
	light,					// Out surface (rgba16float) of lighting passes
	light_combined,			// Combined lighting surfaces (rgba16float) between passes
	
	final,					// Final combined surface before tonemapping (rgba16float)
	post_process,			// Post-processing middle-man surface (rgba16float)
	
	COUNT					// Not a buffer; contains the number of buffers that exist
}

/// @desc	Used by materials to specify which render stage they should appear in.
enum CAMERA_RENDER_STAGE {
	none = 0,			// (camera/material) Does not render at all
	opaque = 1,			// (camera/material) Renders in the opaque pass (all alphas are 0 or 1)
	translucent = 2,	// (camera/material) Renders in the translucent pass (alpha can be [0..1])
	both = 3,			// (camera/material) Renders in both stages (not usually desired)
	
	mixed = 7			// (camera) Renders everything under one stage (used for low-performance devices / special camera effects).
						// Translucent materials will render opaque but w/ a dithering effect to fake translucency.
}

/// @desc	Defines the tonemap to apply when rendering out.
enum CAMERA_TONEMAP {
	linear,		// No tonemapping
	reinhard,
	aces,		// (modified) ACES tonemapping
}

/// @desc	Bitwiseable flags to apply to a camera for debugging purposes.
enum CAMERA_DEBUG_FLAG {
	render_wireframe			=	0b1,		// If used, models should be generated with Primitive.GENERATE_WIREFRAMES=true for an accurate wireframe
	render_collisions			=	0b10,		// Renders collision shapes as wireframe
	render_partitions			=	0b100,		// Renders collidable partition systems
	render_normals				=	0b1000,		// Renders normals instead of the final output
	render_pbr					=	0b10000,	// Renders PBR data instead of final output
	render_depth				=	0b100000,	// Renders the depth buffer
	render_albedo				=	0b1000000,	// Renders albedo buffer; note it's WIPED for each pass!
}

/// @desc	Bitwiseable flags to enable / disable specific rendering pipeline features for the specific camara
enum CAMERA_RENDER_FLAG {
	ppfx				=	0b0001,		// Post processing effects
	shadows				=	0b0010,		// Light shadow processing functions (includes SSAO)
	environment			=	0b0100,		// Environmental reflections
	emission			=	0b1000,		// Emissive texture rendering
	lighting			=	0b10000,	// Lighting (if disabled, renders unlit albedo)
}

/// @desc	The current rendering pass that is being executed.
enum CAMERA_RENDER_PASS {
	gbuffer_mrt = -1,	// All gbuffer textures are rendering (used in normal renderer)
	
	gbuffer_albedo,		// Individual gbuffer texture rendering (used in compatability renderer)
	gbuffer_normal,
	gbuffer_pbr,
	gbuffer_emissive,
	
	light_shadows,		// Shadow rendering in lighting pass
	light,				// Lighting itself
	
	ppfx,				// Post-processing rendering
	debug				// Rendering debug info
}
function Camera() : Body() constructor {
	#region PROPERTIES
	static ACTIVE_INSTANCE = undefined;	// The currently rendering camera instance; not usually used for clarity but available if necessary
	static ACTIVE_STAGE = undefined;
	static ACTIVE_PASS = undefined;
	
	buffer_width = undefined;	// Render resolution
	buffer_height = undefined;
	gbuffer = {
		surfaces : {}, // GBuffer surfaces with IDs from CAMERA_GBUFFER
		textures : {}  // Gbuffer textures, in some cases they do NOT have an equivalent surface!
	};
	render_stages = CAMERA_RENDER_STAGE.both; // Which render stages to perform
	render_tonemap = CAMERA_TONEMAP.linear;
/// @stub	Add post-processing structure & addition / removal / render to camera
	post_process_effects = {};	// priority -> effect pairs for post processing effects
	debug_flags = 0;		// CAMERA_DEBUG_FLAG toggles
	render_flags = -1;		// CAMERA_RENDER_FLAG toggles
	exposure_level = 1.0;
	white_level = 1.0;
	gamma_correction = true;
	#endregion
	
	#region STATIC METHODS
	/// @desc	Returns if the current render stage is opaque. This will return for
	///			the opaque stage AND the mixed stage (as mixed renders to opaque).
	static get_is_opaque_stage = function(stage=Camera.ACTIVE_STAGE){
		return (stage & CAMERA_RENDER_STAGE.opaque);
	}
	
	/// @desc	Returns if the current render stage is translucent. This will only
	///			return if explicitly the translucent stage.
	static get_is_translucent_stage = function(stage=Camera.ACTIVE_STAGE){
		return (stage & CAMERA_RENDER_STAGE.translucent > 0 and stage != CAMERA_RENDER_STAGE.mixed);
	}
	
	/// @desc	Retruns if the current render stage is mixed.
	static get_is_mixed_stage = function(stage=Camera.ACTIVE_STAGE){
		return stage == CAMERA_RENDER_STAGE.mixed;
	}
	#endregion
	
	#region METHODS
	/// @desc	Set which render stages should be rendered. Even when no instances
	///			exist in a render stage, that stage still takes up processing time
	///			and vRAM. E.g., if you KNOW you will never have translucent materials
	///			then disabling the translucent stage will free up vRAM and give you
	///			some extra FPS.
	function set_render_stages(stages=CAMERA_RENDER_STAGE.both){
		render_stages = clamp(floor(stages), 0, 7);
	}
	
	/// @desc	Sets the render size for the camera, in pixels. This size will
	///			be used by each eye maintained by the camera.
	function set_render_size(width, height){
		buffer_width = max(1, floor(real(width)));
		buffer_height = max(1, floor(real(height)));
	}
	
	/// @desc	Sets the tonemap to use when converting the final linearized 
	///			color buffer to the rgba8 channels to display to the screen.
	/// @param	{CAMERA_TONEMAP}	tonemap
	function set_tonemap(tonemap){
		self.render_tonemap = tonemap;
	}
	
	
	/// @desc	Enables or disables a render flag effect. This can be used to
	///			toggle specific features per-camera and separate from lights and
	///			models.
	/// @param	{CAMERA_RENDER_FLAG}	flag	flag (or bitwised flags) to enable or disable
	/// @param	{bool}					enabled	if true, adds the flag otherwise removes it
	function set_render_flag(flag, enabled=true){
		if (enabled)
			render_flags |= flag;
		else
			render_flags &= ~flag;
	}
	
	/// @desc	Enables or disables a debug flag effect.
	/// @param	{CAMERA_DEBUG_FLAG}	flag	flag (or bitwised flags) to enable or disable
	/// @param	{bool}				enabled	if true, adds the flag otherwise removes it
	function set_debug_flag(flag, enabled=true){
		if (enabled)
			debug_flags |= flag;
		else
			debug_flags &= ~flag;
	}
	
	/// @desc	Camera exposure to apply before tonemapping.
	function set_exposure(exposure){
		exposure_level = clamp(exposure, 0, 16);
	}
	
	/// @desc	White level to apply after tonemapping.
	function set_white(white){
		white_level = clamp(white, 0, 16);
	}
	
	/// @desc	Whether or not to apply gamma correction.
	function set_gamma_correction(enabled){
		gamma_correction = bool(enabled);
	}
	
	/// @desc	Return an array of all attached Eye() instances.
	function get_eye_array(){
		return [];
	}
	
	/// @desc	Returns the estimated amount of vRAM used by the gbuffer, in bytes, for this camera.
	///			Does NOT account for body materials or light buffers.
	function get_vram_usage(){
		if (is_undefined(buffer_width) or is_undefined(buffer_height))
			return 0;
			
		var bytes = 0;
		var array = struct_get_values(gbuffer.surfaces);
		for (var i = array_length(array) - 1; i >= 0; --i){
			if (not surface_exists(array[i]))	
				continue;
			
			bytes += (surface_get_format(array[i]) == surface_rgba16float ? 8 : 4);
		}
		return bytes * buffer_width * buffer_height;
	}
	
	/// @desc	Given a buffer index from the GBuffer, returns if it is necessary for
	///			the current render given the camera's current properties.
	function get_requires_buffer(buffer_index){
		if (buffer_index == CAMERA_GBUFFER.albedo or 
			buffer_index == CAMERA_GBUFFER.depth or 
			buffer_index == CAMERA_GBUFFER.light or
			buffer_index == CAMERA_GBUFFER.light_combined)
			return (render_stages & CAMERA_RENDER_STAGE.both) > 0;
		
		if (buffer_index == CAMERA_GBUFFER.normal or 
			buffer_index == CAMERA_GBUFFER.pbr or 
			buffer_index == CAMERA_GBUFFER.view)
			return (render_stages & CAMERA_RENDER_STAGE.both) > 0;
		
		if (buffer_index == CAMERA_GBUFFER.emissive)
			return ((render_stages & CAMERA_RENDER_STAGE.both) > 0) and get_has_render_flag(CAMERA_RENDER_FLAG.emission);
		
		if (buffer_index == CAMERA_GBUFFER.final)
			return (render_stages & CAMERA_RENDER_STAGE.both) > 0;
		
		if (buffer_index == CAMERA_GBUFFER.post_process)
			return ((render_stages & CAMERA_RENDER_STAGE.both) > 0) and get_has_render_flag(CAMERA_RENDER_FLAG.ppfx);
		
		return false;
	}
	
	/// @desc	Returns whether or noth ALL the specified flags are enabled
	/// @param	{CAMERA_RENDER_FLAG}	flag		flag (or bitwised flags) to check for enabled state
	function get_has_render_flag(flag){
		return (render_flags & flag == flag);
	}
	
	/// @desc	Adds a new post processing effect with the specified render priority.
	///			Does NOT check for duplicates.
	/// @param	{PostProcessFX}	effect
	/// @param	{real}			priority
	function add_ppfx(effect, priority=0){
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
		
		if (U3D.RENDERING.force_2n_textures){
			buffer_width = power(2, ceil(log2(buffer_width)));
			buffer_height = power(2, ceil(log2(buffer_height)));
		}
		
		// Check for existence:
		surface_depth_disable(false);
		for (var i = 0; i < CAMERA_GBUFFER.COUNT; ++i){
			if (i == CAMERA_GBUFFER.depth)	// Skip depth, as it is taken from albedo
				continue;
			
			var format = (i >= CAMERA_GBUFFER.view ? surface_rgba16float : surface_rgba8unorm);
			var surface = surfaces[$ i];
				// Don't need the buffer; free if it is allocated:
			if (not get_requires_buffer(i)){
				if (surface_exists(surface))
					surface_free(surface);
				
				surfaces[$ i] = undefined;
				textures[$ i] = undefined;
				continue;
			}
			
			// Buffer required; generate it:
				// If it exists; check resizing needs
			if (surface_exists(surface)){
				if (surface_get_width(surface) != buffer_width or surface_get_height(surface) != buffer_height)
					surface_free(surface);
			}
			
			if (not surface_exists(surface))
				surface = surface_create(buffer_width, buffer_height, format);
			
			surfaces[$ i] = surface;
			textures[$ i] = surface_get_texture(surface);
			// If there is a depth buffer, set the depth cache to it:
			if (not surface_get_depth_disable()){
				surfaces[$ CAMERA_GBUFFER.depth] = surface;
				textures[$ CAMERA_GBUFFER.depth] = surface_get_texture_depth(surface);
			}
			
			surface_depth_disable(true);
		}

		surface_depth_disable(false);
		return true;
	}
	
	/// @desc	A function that gets called after the graphic buffer is allocated
	///			but before any rendering occurs.
	function render_prepass(){
		// The following buffers are SHARED between stages. Note that there may NOT
		// be proper depth-checks when combining!
		var array = struct_get_values(gbuffer.surfaces);
		for (var i = array_length(array) -1; i >= 0; --i)
			surface_clear(array[i], 0, 0);
	}
	
	/// @desc	A function that gets called after the graphics buffer is rendered to
	///			but before any lighting passes happen.
	function render_midpass(){}
	
	/// @desc	A function that gets called after all lighting has occurred but before
	///			the PPFX pass has occurred.
	function render_postpass(){}
	
	/// @desc	Given an array of renderable bodies, the camera will render all the
	///			texture data into the GBuffer to later be passed into the lighting
	///			stage.
	/// @param	{Eye}	eye				the eye we should use for the view and projection
	/// @param	{array}	body_array		array of Body instances to render
	/// @param	{bool}	is_translucent	whether or not this is the translucent pass
	function render_gbuffer(eye, body_array=[]){
		var is_translucent = Camera.get_is_translucent_stage();
		if (not is_translucent and (render_stages & CAMERA_RENDER_STAGE.opaque) <= 0)
			return;
		
		if (is_translucent and (render_stages & CAMERA_RENDER_STAGE.translucent) <= 0)
			return;
		
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		gpu_set_cullmode(cull_noculling);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		
		// Clear the albedo surface while keeping the depth from the last pass:
		if (not surface_exists(gbuffer.surfaces[$ CAMERA_GBUFFER.depth])) // Shared w/ albedo surface
			return false;
			
		if (is_translucent){
			surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.albedo]);
			draw_clear_ext(0, 0);
			surface_reset_target();
			if (get_has_render_flag(CAMERA_RENDER_FLAG.emission)) // Clear emission; albeit it shouldn't ever exist for translucent pass
				surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.emissive], 0, 0);
		}
		
		// Render models w/ materials to primary buffer channels:
		for (var r = 0; r < (U3D.OS.is_compatability ? 4 : 1); ++r){
			#region ATTACH RENDER TARGETS
			// Compatability mode check; must render one texture at a time:
			if (U3D.OS.is_compatability){
				var index_array = [
					CAMERA_GBUFFER.albedo,
					CAMERA_GBUFFER.normal,
					CAMERA_GBUFFER.pbr,
					CAMERA_GBUFFER.emissive
				];
				
				if (not surface_exists(gbuffer.surfaces[$ index_array[r]]))
					continue;
				
				if (r > 0 and not get_has_render_flag(CAMERA_RENDER_FLAG.lighting))
					continue;
				
				/// @note	Seems bugged in browsers; so we unfortunately have to manually sample the depth in the shader.
				///			Only applies to normals, pbr, and emission. Depth is getting wiped if manually set.
				if (U3D.OS.is_browser)
					surface_set_target(gbuffer.surfaces[$ index_array[r]]);
				else 
					surface_set_target(gbuffer.surfaces[$ index_array[r]], gbuffer.surfaces[$ CAMERA_GBUFFER.depth]);
				
				Camera.ACTIVE_PASS = r;
				if (r > 0)
					gpu_set_zwriteenable(false);
			}
			// Regular render mode; attach all render targets:
			else{
				surface_set_target_ext(0, gbuffer.surfaces[$ CAMERA_GBUFFER.albedo]);
				surface_set_target_ext(1, gbuffer.surfaces[$ CAMERA_GBUFFER.normal]);
				surface_set_target_ext(2, gbuffer.surfaces[$ CAMERA_GBUFFER.pbr]);
				if (get_has_render_flag(CAMERA_RENDER_FLAG.emission))
					surface_set_target_ext(3, gbuffer.surfaces[$ CAMERA_GBUFFER.emissive]);
				
				Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.gbuffer_mrt;
			}
			#endregion
			
			#region RENDER MODELS
			var world_matrix = matrix_get(matrix_world); // Cache so we can reset for later stages
			eye.apply();
			for (var i = array_length(body_array) - 1; i >= 0; --i){
				var body = body_array[i];
				if (body.get_render_layers() & get_render_layers() == 0) // This camera doesn't render this body
					continue;
					
				// Make sure model is renderable for this camera
				if (is_undefined(body.model_instance))
					continue;
				
				matrix_set(matrix_world, body.get_model_matrix());
				var data = {
					skeleton : U3D.RENDERING.ANIMATION.SKELETON.missing_quatpos,
					skeleton_bone_count : U3D_MAXIMUM_BONES * 2 // Only defines that we are using quatpos pairs
				}
				if (not is_undefined(body.animation_instance)){
					data.skeleton = body.animation_instance.get_transform_array();
					data.skeleton_bone_count = struct_names_count(body.animation_instance.skeleton);
				}
					
				body.model_instance.render(data);
			}
	
			matrix_set(matrix_world, world_matrix);
			surface_reset_target();
			#endregion
		}
		
		Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.gbuffer_mrt;
		gpu_set_zwriteenable(true);
			
		// Render view vector buffer for use with lighting
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.view]);
		shader_set(shd_view_buffer);
		sampler_set("u_sDepth", gbuffer.textures[$ CAMERA_GBUFFER.depth]);
		uniform_set("u_mInvProj", shader_set_uniform_matrix_array, [eye.get_inverse_projection_matrix()]);
		uniform_set("u_mInvView", shader_set_uniform_matrix_array, [eye.get_inverse_view_matrix()]);
		uniform_set("u_vCamPosition", shader_set_uniform_f, [position.x, position.y, position.z]);
		
		draw_quad(0, 0, buffer_width, buffer_height);
		shader_reset();
		surface_reset_target();
	}
	
	/// @desc	Renders all the shadows and lights, including emissive tetures, and adds
	///			them together on the final light surface.
	/// @param	{Eye}	eye				the eye we should use for the view and projection
	/// @param	{array}	light_array		array of Light instances to render
	/// @param	{array}	body_array		array of Body instances to render
	/// @param	{bool}	is_translucent	whether or not this is the translucent pass
	function render_lighting(eye, light_array=[], body_array=[]){
		var is_translucent = Camera.get_is_translucent_stage();
		if (not is_translucent and (render_stages & CAMERA_RENDER_STAGE.opaque) <= 0)
			return;
		
		if (is_translucent and (render_stages & CAMERA_RENDER_STAGE.translucent) <= 0)
			return;
			
		if (get_has_render_flag(CAMERA_RENDER_FLAG.lighting)){
			Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.light_shadows;
			// Render light shadows:
			if (not is_translucent and render_flags & CAMERA_RENDER_FLAG.shadows == CAMERA_RENDER_FLAG.shadows){ // We only do so for opaque instances
				for (var i = array_length(light_array) - 1; i >= 0; --i){
					if (light_array[i].get_render_layers() & get_render_layers() == 0) // This light is not on the camera's render layer
						continue;
					
					if (not light_array[i].casts_shadows) // Light must have shadows enabled
						continue;
					
					Light.ACTIVE_INSTANCE = light_array[i];
					light_array[i].render_shadows(eye, body_array);
					Light.ACTIVE_INSTANCE = undefined;
				}
			}
			
			Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.light;
	/// @todo	Batch light types together (a shader for each) and pass in multiple
	///			lights into the shader
			surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.light], c_black, 0.0);
			for (var i = array_length(light_array) - 1; i >= 0; --i){
				var light = light_array[i];
				
				if (light.get_render_layers() & get_render_layers() == 0) // This light is not on the camera's render layer
					continue;
				
				if (is_undefined(light.get_light_shader())) // Invalid light
					continue;
	
				Light.ACTIVE_INSTANCE = light;
				shader_set(light.get_light_shader());
				gpu_set_blendmode_ext(bm_one, bm_zero);
				surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.final]); // Repurposed to avoid needing an extra buffer
				draw_clear_alpha(0, 0);
	/// @stub	Optimize having to re-apply the gbuffer for every light. This is due to the deferred shadow pass.
				light.apply_gbuffer();
				light.apply();
				draw_quad(0, 0, buffer_width, buffer_height);
				shader_reset();
				surface_reset_target();
				
				var applied_shadows = false;
				if (render_flags & CAMERA_RENDER_FLAG.shadows == CAMERA_RENDER_FLAG.shadows)
					applied_shadows = light.apply_shadows(eye, gbuffer.surfaces[$ CAMERA_GBUFFER.final], gbuffer.surfaces[$ CAMERA_GBUFFER.light]);
				
				if (not applied_shadows){
					gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_one, bm_one, bm_zero);
					surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.light]);
					draw_surface(gbuffer.surfaces[$ CAMERA_GBUFFER.final], 0, 0);
					surface_reset_target();
				}
				gpu_set_blendmode(bm_normal);
				Light.ACTIVE_INSTANCE = undefined;
			}
			
			if (get_has_render_flag(CAMERA_RENDER_FLAG.emission)){
				// Special render for emissive textures:
				gpu_set_blendmode(bm_add);
				surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.light]);
				shader_set(shd_lighting_emissive);
				sampler_set("u_sEmissive", gbuffer.textures[$ CAMERA_GBUFFER.emissive]);
				draw_quad(0, 0, buffer_width, buffer_height);
				shader_reset();
				
				gpu_set_blendmode(bm_normal);
				surface_reset_target();
			}
		}
		
		// Merge into final light buffer:
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.light_combined]);
		shader_set(shd_clamp_alpha);
		gpu_set_blendequation_sepalpha(bm_eq_add, bm_eq_max);
		gpu_set_blendmode_ext(bm_src_alpha, bm_inv_src_alpha);
		draw_quad(0, 0, buffer_width, buffer_height, get_has_render_flag(CAMERA_RENDER_FLAG.lighting) ? gbuffer.textures[$ CAMERA_GBUFFER.light] : gbuffer.textures[$ CAMERA_GBUFFER.albedo]);
		gpu_set_blendequation_sepalpha(bm_eq_add, bm_eq_add);
		shader_reset();
		surface_reset_target();
		gpu_set_blendmode(bm_normal);
	}
	
	
	function render_debug(eye){
		Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.debug;
		if (debug_flags > 0){
			gpu_set_blendmode_ext(bm_one, bm_zero);
			if (not surface_exists(gbuffer.surfaces[$ CAMERA_GBUFFER.final]))
				return;
				
			surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.final]);
			if (debug_flags & CAMERA_DEBUG_FLAG.render_normals and surface_exists(gbuffer.surfaces[$ CAMERA_GBUFFER.normal]))
				draw_quad_color(0, 0, buffer_width, buffer_height, gbuffer.textures[$ CAMERA_GBUFFER.normal]);
			if (debug_flags & CAMERA_DEBUG_FLAG.render_pbr and surface_exists(gbuffer.surfaces[$ CAMERA_GBUFFER.pbr]))
				draw_quad_color(0, 0, buffer_width, buffer_height, gbuffer.textures[$ CAMERA_GBUFFER.pbr]);
			if (debug_flags & CAMERA_DEBUG_FLAG.render_depth and surface_exists(gbuffer.surfaces[$ CAMERA_GBUFFER.depth])){
				shader_set(shd_depth_to_grayscale);
				uniform_set("u_vZClip", shader_set_uniform_f, [get_eye().get_znear(), get_eye().get_zfar()]);
				draw_quad_color(0, 0, buffer_width, buffer_height, gbuffer.textures[$ CAMERA_GBUFFER.depth]);
				shader_reset();
			}
			if (debug_flags & CAMERA_DEBUG_FLAG.render_albedo and surface_exists(gbuffer.surfaces[$ CAMERA_GBUFFER.albedo]))
				draw_quad_color(0, 0, buffer_width, buffer_height, gbuffer.textures[$ CAMERA_GBUFFER.albedo]);
				
			surface_reset_target();
		}
		
		var body_array = [];
		if (debug_flags & CAMERA_DEBUG_FLAG.render_collisions == CAMERA_DEBUG_FLAG.render_collisions and instance_exists(obj_collision_controller)){
			var matrix_model = matrix_get(matrix_world);
			if (array_length(body_array) <= 0)
				body_array = obj_collision_controller.get_body_array();
				
			gpu_set_blendmode_ext(bm_one, bm_zero);
			surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.final]);
			
			eye.apply();
			
			shader_set(shd_debug_lines);
			sampler_set("u_sDepth", gbuffer.textures[$ CAMERA_GBUFFER.depth]);
			uniform_set("u_vTexelSize", shader_set_uniform_f, [texture_get_texel_width(gbuffer.textures[$ CAMERA_GBUFFER.depth]), texture_get_texel_height(gbuffer.textures[$ CAMERA_GBUFFER.depth])])
			
			// Individual collision bodies:
			for (var i = array_length(body_array) - 1; i >= 0; --i){
				var body = body_array[i];
				var collidable = body.get_collidable();
				if (not U3DObject.get_is_valid_object(collidable))
					continue;
				
				collidable.render_debug(body);
			}

			shader_reset();
			surface_reset_target();
			
			gpu_set_blendmode(bm_normal);
			matrix_set(matrix_world, matrix_model);
			draw_set_color(c_white);
			draw_set_alpha(1);
		}
		
		if (debug_flags & CAMERA_DEBUG_FLAG.render_partitions == CAMERA_DEBUG_FLAG.render_partitions and instance_exists(obj_collision_controller)){
			var matrix_model = matrix_get(matrix_world);
			gpu_set_blendmode_ext(bm_one, bm_zero);
			surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.final]);
			
			eye.apply();
			
			shader_set(shd_debug_lines);
			sampler_set("u_sDepth", gbuffer.textures[$ CAMERA_GBUFFER.depth]);
			uniform_set("u_vTexelSize", shader_set_uniform_f, [texture_get_texel_width(gbuffer.textures[$ CAMERA_GBUFFER.depth]), texture_get_texel_height(gbuffer.textures[$ CAMERA_GBUFFER.depth])])
			
			// Partition systems:
			with (obj_collision_controller)
				partition_system.render_debug()

			shader_reset();
			surface_reset_target();
			
			gpu_set_blendmode(bm_normal);
			matrix_set(matrix_world, matrix_model);
			draw_set_color(c_white);
			draw_set_alpha(1);
		}
	}
	/// @desc	Renders all the PostProcessFX added to the camera in order of priority.
	///			Executes on the current GBuffer state.
	function render_ppfx(){
		if (render_stages <= 0)
			return;

		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.final]);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		draw_clear_alpha(0, 0);
		shader_set(shd_clamp_alpha);
		draw_quad(0, 0, buffer_width, buffer_height, gbuffer.textures[$ CAMERA_GBUFFER.light_combined]);
		gpu_set_blendmode(bm_normal);
		shader_reset();
		surface_reset_target();
		
		if (struct_names_count(post_process_effects) <= 0 or render_flags & CAMERA_RENDER_FLAG.ppfx != CAMERA_RENDER_FLAG.ppfx)
			return;

		Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.ppfx;
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
				
			gpu_set_blendmode_ext(bm_one, bm_zero);
			if (not data.render(gbuffer.surfaces[$ CAMERA_GBUFFER.post_process]))
				continue;

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
	/// @param	{array}	body_array		the array of renderable bodies to process
	/// @param	{array}	light_array		the array of renderable lights to process
	function render_eye(eye, body_array=[], light_array=[]){
		if (not is_instanceof(eye, Eye))
			throw new Exception("invalid type, expected [Eye]!");
		
		if (not U3DObject.are_equal(eye.get_camera(), self))
			throw new Exception("eye does not belong to rendering camera!");
		
		Camera.ACTIVE_INSTANCE = self;
		Eye.ACTIVE_INSTANCE = eye;

		// Make sure the GBuffer exists and is valid
		if (not generate_gbuffer())
			return;
			
		render_prepass();

		if (render_stages == CAMERA_RENDER_STAGE.mixed){
			Camera.ACTIVE_STAGE = CAMERA_RENDER_STAGE.mixed;
			render_gbuffer(eye, body_array);
			
			render_midpass();
			render_lighting(eye, light_array, body_array);
		}
		else {
			// Opaque pass:
			Camera.ACTIVE_STAGE = CAMERA_RENDER_STAGE.opaque;
			render_gbuffer(eye, body_array);
			
			render_midpass();
			render_lighting(eye, light_array, body_array);
	
			// Translucent pass:
			Camera.ACTIVE_STAGE = CAMERA_RENDER_STAGE.translucent;
			render_gbuffer(eye, body_array);
			
			render_midpass();
			render_lighting(eye, light_array, body_array);
		}
		
		Camera.ACTIVE_STAGE = CAMERA_RENDER_STAGE.none;
		
		render_postpass();
		
		// Post-processing:
		render_ppfx();
		
		// Debug render:
		render_debug(eye);
		
		Camera.ACTIVE_INSTANCE = undefined;
		Eye.ACTIVE_INSTANCE = undefined;
		Camera.ACTIVE_PASS = CAMERA_RENDER_PASS.gbuffer_mrt;
	}
	
	/// @desc	Should execute a render_eye for every eye and combine results
	///			as necessary.
	function render(body_array, light_array){
		var eye_array = get_eye_array();
		for (var i = array_length(eye_array) - 1; i >= 0; --i)
			render_eye(eye_array[i], body_array, light_array);
	};
	
	/// @desc	Should push the final result to the final render destination; 
	///			whether that be the monitor, a VR headset, or a custom textured
	///			surface.
	function render_out(){};
	#endregion
}