/// @about
/// A directional light that has an equal effect on all elements in the scene.
/// The light faces down the x-axis by default and can be rotated via a
/// quaternion.
/// Shadows are handled through a single shadow map. Cascade shadows are not
/// supported at this time. It is best to make the light node 'follow' your camera
/// so shadows are always centered around the camera.

/// @desc	a new directional light that casts light evenly on all elements in
///			the scene. While a position is not necessary for lighting up objects
///			it does become necessary for casting shadows and instance 'culling'.
function LightDirectional(rotation=quat(), position=vec()) : Light() constructor {
	#region PROPERTIES
	shader_lighting = shd_lighting_directional;
	light_normal = vec_normalize(quat_rotate_vec(rotation, vec(1, 0, 0)));
	light_color = c_white;
	texture_environment = undefined;
	
	shadow_resolution = 4096;	// Texture resolution for the lighting render (larger = sharper shadows but more expensive)
	shadow_world_units = 64;	// Number of world-units width/height-wise the shadow map should cover (larger = more of the world has shadows but blurrier)
	shadow_surface = -1;		// Only used to extract the depth buffer
	shadowbit_surface = -1;		// Used in the deferred pass for shadow sampling
	shadow_depth_texture = -1;
	shadow_znear = 0.01;		// How close to the light things will render
	shadow_zfar = 1024;			// How far away from the light things will render
	shadow_bias = 0.00005;		// Depth-map bias (larger can remove shadow acne but may cause 'peter-panning')
	shadow_viewprojection_matrix = matrix_build_identity();	// Will calculate if shadows are enabled
	
	#region SHADER UNIFORMS
	uniform_sampler_albedo = -1;
	uniform_sampler_normal = -1;
	uniform_sampler_pbr = -1;
	uniform_sampler_view = -1;
	uniform_sampler_environment = -1;
	uniform_shadow_sampler_shadow = -1;
	uniform_shadow_sampler_depth = -1;     
	uniform_shadow_sampler_albedo = -1;
	uniform_shadow_alpha_cutoff = -1;
	#endregion
	#endregion
	
	#region METHODS

	/// @desc	Sets several properties for the shadow rendering, if enabled.
	/// @param	{real}	resolution=4096		resolution of shadow texture to render to
	/// @param	{real}	units=64			world units the render camera should cover
	/// @param	{real}	bias=0.00005		sample depth offset; used to balance shadow acne / peter panning issues
	/// @param	{real}	znear=0.01			near clipping distance for the shadow's camera
	/// @param	{real}	zfar=1024			far clipping distance for the shadow's camera
	function set_shadow_properties(resolution=4096, units=64, bias=0.00005, znear=0.01, zfar=1024){
		shadow_resolution = resolution;
		shadow_world_units = units;
		shadow_bias = bias;
		shadow_znear = znear;
		shadow_zfar = zfar;
	}
	
	function set_color(color=c_white){
		light_color = color;
	}
	
	/// @desc	Sets an environment texture to be used for reflections. If set to anything
	///			other than 'undefined' environmental mapping will be enabled for this light.
	/// @param	{TextureCube}	texture=undefined		a TextureCube texture, specifying the cube-map to use
	function set_environment_texture(texture=undefined){
		if (not is_undefined(texture) and not is_instanceof(texture, TextureCube))
			throw new Exception("invalid type, expected [TextureCube]!");
			
		texture_environment = texture;
	}
	
	function apply_gbuffer(camera_id, is_translucent=false){
		if (uniform_sampler_albedo < 0)
			uniform_sampler_albedo = shader_get_sampler_index(shader_lighting, "u_sAlbedo");
		
		if (uniform_sampler_normal < 0)
			uniform_sampler_normal = shader_get_sampler_index(shader_lighting, "u_sNormal");
		
		if (uniform_sampler_pbr < 0)
			uniform_sampler_pbr = shader_get_sampler_index(shader_lighting, "u_sPBR");
		
		if (uniform_sampler_view < 0)
			uniform_sampler_view = shader_get_sampler_index(shader_lighting, "u_sView");
		
		if (uniform_sampler_environment < 0)
			uniform_sampler_environment = shader_get_sampler_index(shader_lighting, "u_sEnvironment");
		
		texture_set_stage(uniform_sampler_albedo, camera_id.gbuffer.textures[$ is_translucent ? CAMERA_GBUFFER.albedo_translucent : CAMERA_GBUFFER.albedo_opaque]);
		texture_set_stage(uniform_sampler_normal, camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal]);
		texture_set_stage(uniform_sampler_pbr, camera_id.gbuffer.textures[$ CAMERA_GBUFFER.pbr]);
		texture_set_stage(uniform_sampler_view, camera_id.gbuffer.textures[$ CAMERA_GBUFFER.view]);
		
		if (not is_undefined(texture_environment)){
			texture_set_stage(uniform_sampler_environment, texture_environment.get_texture());
			uniform_set("u_iEnvironment", shader_set_uniform_i, true);
			uniform_set("u_iMipCount", shader_set_uniform_i, [not is_instanceof(texture_environment, TextureCubeMip) ? 0 : texture_environment.mip_count]);
		}
		else
			uniform_set("u_iEnvironment", shader_set_uniform_i, false);
	}
	
	function apply(){
/// @stub	Figure out why the light needs these two axes inverted
		uniform_set("u_vLightNormal", shader_set_uniform_f, [-light_normal.x, -light_normal.y, -light_normal.z]);
		uniform_set("u_vLightColor", shader_set_uniform_f, [color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255]);
	}
	
	function render_shadows(eye_id=undefined, body_array=[]){
		surface_depth_disable(false);
		if (not surface_exists(shadow_surface))
			shadow_surface = surface_create(shadow_resolution, shadow_resolution, surface_r8unorm);
		
		if (surface_get_width(shadow_surface) != shadow_resolution)
			surface_resize(shadow_surface, shadow_resolution, shadow_resolution);
			
		if (uniform_shadow_sampler_albedo < 0)
			uniform_shadow_sampler_albedo = shader_get_sampler_index(shd_light_depth, "u_sAlbedo");
		
		if (uniform_shadow_alpha_cutoff < 0)
			uniform_shadow_alpha_cutoff = shader_get_sampler_index(shd_light_depth, "u_fAlphaCutoff");
			
		shadow_depth_texture = surface_get_texture_depth(shadow_surface);
		surface_set_target(shadow_surface);
		var mv = matrix_get(matrix_view);
		var mp = matrix_get(matrix_projection);
		var mw = matrix_get(matrix_world);
		draw_clear(c_white);
		shader_set(shd_light_depth);
		
		var forward = get_forward_vector();
		var lookat = vec_add_vec(position, forward);
		matrix_set(matrix_view, matrix_build_lookat(position.x, position.y, position.z, lookat.x, lookat.y, lookat.z, 0, 1, 0));
		matrix_set(matrix_projection, matrix_build_projection_ortho(shadow_world_units, shadow_world_units, shadow_znear, shadow_zfar));
		shadow_viewprojection_matrix = matrix_multiply(matrix_get(matrix_view), matrix_get(matrix_projection));
		
		for (var i = array_length(body_array) - 1; i >= 0; --i){
			var body = body_array[i];
			if (body.get_render_layers() & get_render_layers() == 0) // This light doesn't render this body
				continue;
				
			// Make sure model is renderable for this light
			if (is_undefined(body.model_instance))
				continue;
			
			matrix_set(matrix_world, body.get_model_matrix());
			body.model_instance.render_shadows();
		}
		shader_reset();
		matrix_set(matrix_view, mv);
		matrix_set(matrix_projection, mp);
		matrix_set(matrix_world, mw);
		surface_reset_target();
	}
	
	function apply_shadows(eye_id, surface_in, surface_out){
		if (not casts_shadows){
			if (surface_exists(shadowbit_surface)){
				surface_free(shadowbit_surface);
				shadowbit_surface = -1;
			}
			return false;
		}
		
		var sw = surface_get_width(eye_id.get_camera().gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque]);
		var sh = surface_get_height(eye_id.get_camera().gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque]);
		
		if (surface_exists(shadowbit_surface) and surface_get_width(shadowbit_surface) != sw or surface_get_height(shadowbit_surface) != sh)
			surface_free(shadowbit_surface);
			
		if (not surface_exists(shadowbit_surface))
			shadowbit_surface = surface_create(sw, sh, surface_r8unorm);

		surface_clear(shadowbit_surface, c_black);
		
		if (uniform_shadow_sampler_shadow < 0)
			uniform_shadow_sampler_shadow = shader_get_sampler_index(shd_lighting_sample_shadow, "u_sShadow");
		
		if (uniform_shadow_sampler_depth < 0)
			uniform_shadow_sampler_depth = shader_get_sampler_index(shd_lighting_sample_shadow, "u_sDepth");
		
		/// Render to shadow buffer
		/// @note	This was done as an MRT in the lighting pass, but the Windows platform
		///			was failing to write out for some reason so we switched to a separate pass.
		surface_set_target(shadowbit_surface);
		shader_set(shd_lighting_sample_shadow);
		texture_set_stage(uniform_shadow_sampler_shadow, shadow_depth_texture);
		texture_set_stage(uniform_shadow_sampler_depth, eye_id.get_camera().gbuffer.textures[$ CAMERA_GBUFFER.depth_opaque]);
		uniform_set("u_fShadowBias", shader_set_uniform_f, shadow_bias);
		uniform_set("u_mShadow", shader_set_uniform_matrix_array, [shadow_viewprojection_matrix]);
		uniform_set("u_mInvProj", shader_set_uniform_matrix_array, [eye_id.get_inverse_projection_matrix()]);
		uniform_set("u_mInvView", shader_set_uniform_matrix_array, [eye_id.get_inverse_view_matrix()]);
		
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(0, 0, 0, 0);
		draw_vertex_texture(sw, 0, 1, 0);
		draw_vertex_texture(0, sh, 0, 1);
		draw_vertex_texture(sw, sh, 1, 1);
		draw_primitive_end();
		
		shader_reset();
		surface_reset_target();
		
		// Process shadow buffer and apply to lighting:
		gpu_set_blendmode(bm_add);
		surface_set_target(surface_out);
		shader_set(shd_lighting_apply_shadow);
		texture_set_stage(shader_get_sampler_index(shd_lighting_apply_shadow, "u_sShadow"), surface_get_texture(shadowbit_surface));
		uniform_set("u_vTexelSize", shader_set_uniform_f, [1.0 / surface_get_width(surface_in), 1.0 / surface_get_height(surface_in)]);
		draw_surface(surface_in, 0, 0);
		shader_reset();
		surface_reset_target();
		
		return true;
	}
	
	// Self-executing signal to update light direction so as to prevent re-calculating every frame
	// if the light is static.
	function _signal_rotation_updated(from_quat, to_quat){
		light_normal = vec_normalize(quat_rotate_vec(to_quat, vec(1, 0, 0)));
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		if (surface_exists(shadow_surface))
			surface_free(shadow_surface);
		
		shadow_surface = -1;
		
		if (surface_exists(shadowbit_surface))
			surface_free(shadowbit_surface);
		
		shadowbit_surface = -1;
	}

	#endregion
	
	#region INIT
	set_position(position);
	set_rotation(rotation);
	signaler.add_signal("set_rotation", new Callable(self, _signal_rotation_updated));
	#endregion
}