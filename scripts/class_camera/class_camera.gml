/// @about
/// A 3D camera that handles rendering for a specific view in 3D space.
/// Can assume to look down the x+ axis w/ a y+up value

/// @desc	Defines the necessary buffers we will need for the graphics pipeline
///			for this camera. We use separate albedo/depth pairs simply for the
///			depth buffer.
enum CAMERA_GBUFFER {
	albedo_opaque,			// Albedo color (rgba8unorm)
	albedo_translucent,
	depth_opaque,			// Depth map; taken from albedo
	depth_translucent,	
	normal,					// Normal map (rgba8unorm)
	pbr,					// PBR properties (rgba8unorm); R: specular, G: roughness, B: metal
	
	out_opaque,				// Out surface (rgba16float) of lighting pass
	out_translucent
}

/// @desc	defines the tonemapping to use for the camera; 'none' is a straight
///			render while every other option will enable HDR and 4x the vRAM usage
enum CAMERA_TONEMAP {
	none,
}

/// @desc	Creates a new 3D camera that can be moved around the world and added
///			to the rendering pipeline.
function Camera(znear=0.01, zfar=1024.0, fov=50) : Node() constructor{
	#region PROPERTIES
	anchor = new CameraAnchor(self);
	tonemap = CAMERA_TONEMAP.none;
	exposure = 1.0;		// (only applies when tonemap != none), the exposure level for the camera
	buffer_width = undefined;
	buffer_height = undefined;
	self.znear = znear;
	self.zfar = zfar;	// y-FOV
	self.fov = fov;
	
	gbuffer = {
		surfaces : {},
		textures : {}
	};
	#endregion
	
	#region METHODS
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
		
		var aspect = -buffer_width / buffer_height;
		var yfov = 2 * arctan(dtan(fov/2) * aspect);
		
		if (get_is_directx_pipeline()){
			aspect = -aspect;
			yfov = -yfov;
		}
		
		var h = 1 / tan(yfov * 0.5);
		var w = h / aspect;
		var a = zfar / (zfar - znear);
		var b = (-znear * zfar) / (zfar - znear);
		var matrix = [
			w, 0, 0, 0,
			0, h, 0, 0,
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
		if (not surface_exists(application_surface))
			return;
			
		/// @note	the depth texture doesn't have its own surface as it is
		///			taken from the depth buffer of the albedo surface
		var screen_width = surface_get_width(application_surface);
		var screen_height = surface_get_height(application_surface);
		buffer_width = anchor.get_dx(screen_width);
		buffer_height = anchor.get_dy(screen_height);
		var surfaces = gbuffer.surfaces;
		var textures = gbuffer.textures;
		
		// Check for existence:
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.albedo_opaque])){
			surface_depth_disable(false);
			surfaces[$ CAMERA_GBUFFER.albedo_opaque] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.albedo_opaque] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.albedo_opaque]);
			// textures[$ CAMERA_GBUFFER.depth_opaque] = surface_get_texture_depth(surfaces[$ CAMERA_GBUFFER.albedo_opaque]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.albedo_translucent])){
			surface_depth_disable(false);
			surfaces[$ CAMERA_GBUFFER.albedo_translucent] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.albedo_translucent] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.albedo_translucent]);
			// textures[$ CAMERA_GBUFFER.depth_translucent] = surface_get_texture_depth(surfaces[$ CAMERA_GBUFFER.albedo_translucent]);
		}
		
		surface_depth_disable(true);
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.depth_opaque])){
			surfaces[$ CAMERA_GBUFFER.depth_opaque] = surface_create(buffer_width, buffer_height, surface_r32float);
			textures[$ CAMERA_GBUFFER.depth_opaque] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.depth_opaque]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.depth_translucent])){
			surfaces[$ CAMERA_GBUFFER.depth_translucent] = surface_create(buffer_width, buffer_height, surface_r32float);
			textures[$ CAMERA_GBUFFER.depth_translucent] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.depth_translucent]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.normal])){
			surfaces[$ CAMERA_GBUFFER.normal] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.normal] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.normal]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.pbr])){
			surfaces[$ CAMERA_GBUFFER.pbr] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.pbr] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.pbr]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.out_opaque])){
			surfaces[$ CAMERA_GBUFFER.out_opaque] = surface_create(buffer_width, buffer_height, surface_rgba16float);
			textures[$ CAMERA_GBUFFER.out_opaque] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.out_opaque]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.out_translucent])){
			surfaces[$ CAMERA_GBUFFER.out_translucent] = surface_create(buffer_width, buffer_height, surface_rgba16float);
			textures[$ CAMERA_GBUFFER.out_translucent] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.out_translucent]);
		}
		surface_depth_disable(false);
		
		// Check for resizing:
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.albedo_opaque], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo_translucent]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.albedo_opaque]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.albedo_translucent], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.depth_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.depth_opaque]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.depth_opaque], buffer_width, buffer_height);
			
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.depth_translucent]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.depth_translucent]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.depth_translucent], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.normal], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.pbr], buffer_width, buffer_height);
			
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.out_opaque]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.out_opaque]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.out_opaque], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.pbr], buffer_width, buffer_height);
	}
	
	/// @desc	Given an array of renderable bodies, the camera will render them
	///			out to the GBuffer.
	function render_gbuffer(body_array=[], is_translucent=false){
		generate_gbuffer();	// Re-generate if not yet generated
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		gpu_set_cullmode(cull_noculling);
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		gpu_set_texrepeat(true);
		
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque + is_translucent], 0, 0);
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.normal], 0);
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.pbr], 0, 0);
		surface_clear(gbuffer.surfaces[$ CAMERA_GBUFFER.depth_opaque + is_translucent], c_white);
		
		surface_set_target_ext(0, gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque + is_translucent]);
		surface_set_target_ext(1, gbuffer.surfaces[$ CAMERA_GBUFFER.normal]);
		surface_set_target_ext(2, gbuffer.surfaces[$ CAMERA_GBUFFER.pbr]);
		surface_set_target_ext(3, gbuffer.surfaces[$ CAMERA_GBUFFER.depth_opaque + is_translucent]);
		var world_matrix = matrix_get(matrix_world); // Cache so we can reset for later stages
		matrix_set(matrix_view, get_view_matrix());
		matrix_set(matrix_projection, get_projection_matrix());
		for (var i = array_length(body_array) - 1; i >= 0; --i){
			var body = body_array[i];
			// Make sure model is renderable for this camera
			if (is_undefined(body.model_instance))
				continue;
			
			matrix_set(matrix_world, body.get_model_matrix());
			body.model_instance.render(RENDER_STAGE.build_gbuffer, self);
		}
		matrix_set(matrix_world, world_matrix);
		surface_reset_target();
	}
	
	function render_lighting(light_array=[], body_array=[], is_translucent=false){
		// Render light shadows:
		if (not is_translucent){ // We only do so for opaque instances
			for (var i = array_length(light_array) - 1; i >= 0; --i){
				if (not light_array[i].casts_shadows) // Light must have shadows enabled
					continue;
				
				light_array[i].render_shadows(gbuffer.textures, body_array, self);
			}
		}
		
/// @stub	Batch light types together (a shader for each) and pass in multiple
///			lights into the shader
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.out_opaque + is_translucent]);
		draw_clear(c_black);
		gpu_set_blendmode(bm_add);
		for (var i = array_length(light_array) - 1; i >= 0; --i){
			var light = light_array[i];
			if (is_undefined(light.get_shader())) // Invalid light
				continue;

			if (shader_current() != light.get_shader()){
				shader_set(light.get_shader());
				light.apply_gbuffer(gbuffer.textures, self);
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
		gpu_set_blendmode(bm_normal);
		surface_reset_target();
	}
	
	function render_post_processing(){
		
/// @stub	Implement; all the following is just for testing anti-aliasing
		gpu_set_blendmode_ext(bm_one, bm_zero);
		surface_set_target(gbuffer.surfaces[$ CAMERA_GBUFFER.out_translucent]);
		draw_clear_alpha(0, 0);
		shader_set(shd_fxaa);
		shader_set_uniform_f(shader_get_uniform(shd_fxaa, "u_vTexsize"), buffer_width, buffer_height);
		draw_surface(gbuffer.surfaces[$ CAMERA_GBUFFER.out_opaque], 0, 0);
		shader_reset();
		surface_reset_target();
	};
	
	/// @desc	Renders to the screen and converts back into sRGB
	function render_out(){
/// @stub	Figure out where to combine gbuffer outputs into a single result (here? before post process?)
		shader_set(shd_finalize);
		draw_surface(gbuffer.surfaces[$ CAMERA_GBUFFER.out_translucent], 0, 0); /// @stub Transluscent because we are temporarily using it for FXAA
		shader_reset();
	}
	super.mark("free");
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