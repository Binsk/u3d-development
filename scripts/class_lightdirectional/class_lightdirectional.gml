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
	uniform_sampler_shadow = -1;	
	uniform_sampler_environment = -1;
	uniform_sampler_depth = -1;
	uniform_shadows = -1;
	uniform_shadow_matrix = -1;
	uniform_shadow_bias = -1;
	uniform_normal = -1;
	uniform_color = -1;
	uniform_albedo = -1;
	uniform_environment = -1;
	uniform_inv_projmatrix = -1;
	uniform_inv_viewmatrix = -1;
	uniform_cam_position = -1;
	uniform_texel_size = -1;
	
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
	
	function apply_gbuffer(gbuffer, camera_id, is_translucent=false){
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
		
		if (uniform_sampler_depth < 0)
			uniform_sampler_depth = shader_get_sampler_index(shader_lighting, "u_sDepth");
		
		if (uniform_sampler_shadow < 0)
			uniform_sampler_shadow = shader_get_sampler_index(shader_lighting, "u_sShadow");
		
		if (uniform_shadows < 0)
			uniform_shadows = shader_get_uniform(shader_lighting, "u_iShadows");
		
		if (uniform_shadow_bias < 0)
			uniform_shadow_bias = shader_get_uniform(shader_lighting, "u_fShadowBias");
			
		if (uniform_shadow_matrix < 0)
			uniform_shadow_matrix = shader_get_uniform(shader_lighting, "u_mShadow")
		
		if (uniform_normal < 0)
			uniform_normal = shader_get_uniform(shader_lighting, "u_vLightNormal");
		
		if (uniform_color < 0)
			uniform_color = shader_get_uniform(shader_lighting, "u_vLightColor");
		
		if (uniform_inv_projmatrix < 0)
			uniform_inv_projmatrix = shader_get_uniform(shader_lighting, "u_mInvProj");
		
		if (uniform_inv_viewmatrix < 0)
			uniform_inv_viewmatrix = shader_get_uniform(shader_lighting, "u_mInvView");
		
		if (uniform_environment < 0)
			uniform_environment = shader_get_uniform(shader_lighting, "u_iEnvironment");
		
		if (uniform_cam_position < 0)
			uniform_cam_position = shader_get_uniform(shader_lighting, "u_vCamPosition");
		
		texture_set_stage(uniform_sampler_albedo, gbuffer[$ is_translucent ? CAMERA_GBUFFER.albedo_translucent : CAMERA_GBUFFER.albedo_opaque]);
		texture_set_stage(uniform_sampler_normal, gbuffer[$ CAMERA_GBUFFER.normal]);
		texture_set_stage(uniform_sampler_pbr, gbuffer[$ CAMERA_GBUFFER.pbr]);
		texture_set_stage(uniform_sampler_view, gbuffer[$ CAMERA_GBUFFER.view]);
		if (not is_translucent and casts_shadows){
			texture_set_stage(uniform_sampler_shadow, shadow_depth_texture);
			texture_set_stage(uniform_sampler_depth, gbuffer[$ CAMERA_GBUFFER.depth_opaque]);
			shader_set_uniform_i(uniform_shadows, true);
			shader_set_uniform_f(uniform_shadow_bias, shadow_bias);
			shader_set_uniform_f(uniform_texel_size, texture_get_texel_width(gbuffer[$ CAMERA_GBUFFER.albedo_opaque]), texture_get_texel_height(gbuffer[$ CAMERA_GBUFFER.albedo_opaque]));
			shader_set_uniform_matrix_array(uniform_shadow_matrix, shadow_viewprojection_matrix);
			shader_set_uniform_matrix_array(uniform_inv_projmatrix, matrix_get_inverse(camera_id.get_projection_matrix()));
			shader_set_uniform_matrix_array(uniform_inv_viewmatrix, matrix_get_inverse(camera_id.get_view_matrix()));
		}
		else
			shader_set_uniform_i(uniform_shadows, false);
		
		if (not is_undefined(texture_environment)){
			texture_set_stage(uniform_sampler_environment, texture_environment.get_texture());
			shader_set_uniform_i(uniform_environment, true);
		}
		else
			shader_set_uniform_i(uniform_environment, false);
	}
	
	function apply(){
/// @stub	Figure out why the light needs these two axes inverted
		shader_set_uniform_f(uniform_normal, light_normal.x, -light_normal.y, -light_normal.z);
		shader_set_uniform_f(uniform_color, color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255);
		
		if (casts_shadows and surface_exists(shadowbit_surface))
			surface_set_target_ext(1, shadowbit_surface);
	}
	
	function render_shadows(gbuffer=[], body_array=[], camera_id=undefined){
		surface_depth_disable(false);
		if (not surface_exists(shadow_surface))
			shadow_surface = surface_create(shadow_resolution, shadow_resolution, surface_r8unorm);
		
		if (surface_get_width(shadow_surface) != shadow_resolution)
			surface_resize(shadow_surface, shadow_resolution, shadow_resolution);
		
		var sw = 1.0 / texture_get_texel_width(gbuffer[$ CAMERA_GBUFFER.albedo_opaque]);
		var sh = 1.0 / texture_get_texel_height(gbuffer[$ CAMERA_GBUFFER.albedo_opaque]);
		if (not surface_exists(shadowbit_surface))
			shadowbit_surface = surface_create(sw, sh, surface_r8unorm);
		
		if (surface_get_width(shadowbit_surface) != sw or surface_get_height(shadowbit_surface) != sh)
			surface_resize(shadowbit_surface, sw, sh);
		
		surface_clear(shadowbit_surface, c_white, 1.0);
			
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
	
	function apply_shadows(surface_in, surface_out){
		if (not casts_shadows){
			if (surface_exists(shadowbit_surface)){
				surface_free(shadowbit_surface);
				shadowbit_surface = -1;
			}
			return false;
		}
		
		if (uniform_texel_size < 0)
			uniform_texel_size = shader_get_uniform(shd_lighting_apply_shadow, "u_vTexelSize");
		
		surface_set_target(surface_out);
		shader_set(shd_lighting_apply_shadow);
		texture_set_stage(shader_get_sampler_index(shd_lighting_apply_shadow, "u_sShadow"), surface_get_texture(shadowbit_surface));
		shader_set_uniform_f(uniform_texel_size, 1.0 / surface_get_width(surface_in), 1.0 / surface_get_height(surface_in));
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