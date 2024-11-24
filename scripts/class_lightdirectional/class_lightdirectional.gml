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
	light_intensity = 1.0;
	texture_environment = undefined;
	
	shadow_resolution = 4096;	// Texture resolution for the lighting render (larger = sharper shadows but more expensive)
	shadow_world_units = 64;	// Number of world-units width/height-wise the shadow map should cover (larger = more of the world has shadows but blurrier)
	shadow_surface = -1;		// Only used to extract the depth buffer ATM (might be used for colored translucent shadows later)
	shadowbit_surface = -1;		// Used in the deferred pass for shadow sampling
	shadow_depth_texture = -1;	// Extracted from shadow_surface
	shadow_znear = 0.01;		// How close to the light things will render
	shadow_zfar = 1024;			// How far away from the light things will render
	shadow_bias = 0.0001;		// Depth-map bias (larger can remove shadow acne but may cause 'peter-panning')
	shadow_sample_bias = 0.0001;// Depth-sampling bias (larger causes shadow halos while smaller can cause acne & lack of smoothing; balance w/ view distanec)
	shadow_viewprojection_matrix = matrix_build_identity();	// Will calculate if shadows are enabled
	#endregion
	
	#region METHODS

	/// @desc	Sets several properties for the shadow rendering, if enabled.
	/// @param	{real}	resolution	resolution of shadow texture to render to
	/// @param	{real}	units		world units the render camera should cover
	/// @param	{real}	bias		sample depth offset; used to balance shadow acne / peter panning issues
	/// @param	{real}	znear		near clipping distance for the shadow's camera
	/// @param	{real}	zfar		far clipping distance for the shadow's camera
	function set_shadow_properties(resolution=4096, units=64, bias=0.0001, znear=0.01, zfar=1024, sample_bias=0.0001){
		shadow_resolution = resolution;
		shadow_world_units = units;
		shadow_bias = bias;
		shadow_znear = znear;
		shadow_zfar = zfar;
		shadow_sample_bias = max(0, sample_bias);
	}
	
	/// @desc	Sets the color of the light's albedo.
	function set_color(color=c_white){
		light_color = color;
	}
	
	/// @desc	Set the lighting intensity which multiplies against the light's
	///			color in the shader.
	function set_intensity(intensity=1.0){
		self.light_intensity = max(0, intensity);
	}
	
	/// @desc	Sets an environment texture to be used for reflections. If set to anything
	///			other than 'undefined' environmental mapping will be enabled for this light.
	/// @param	{TextureCube}	texture	a TextureCube texture, specifying the cube-map to use
	function set_environment_texture(texture=undefined){
		if (not is_undefined(texture) and not is_instanceof(texture, TextureCube))
			throw new Exception("invalid type, expected [TextureCube]!");
			
		replace_child_ref(texture, texture_environment);
		texture_environment = texture;
	}
	
	function apply_gbuffer(){
		var camera_id = Camera.ACTIVE_INSTANCE;
		var is_translucent = Camera.get_is_translucent_stage();
		sampler_set("u_sAlbedo", camera_id.gbuffer.textures[$ is_translucent ? CAMERA_GBUFFER.albedo_translucent : CAMERA_GBUFFER.albedo_opaque]);
		sampler_set("u_sNormal", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.normal]);
		sampler_set("u_sPBR", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.pbr]);
		sampler_set("u_sView", camera_id.gbuffer.textures[$ CAMERA_GBUFFER.view]);
		
		if (not is_undefined(texture_environment) and camera_id.get_has_render_flag(CAMERA_RENDER_FLAG.environment)){
			sampler_set("u_sEnvironment", texture_environment.get_texture());
			uniform_set("u_iEnvironment", shader_set_uniform_i, true);
			uniform_set("u_iMipCount", shader_set_uniform_i, [not is_instanceof(texture_environment, TextureCubeMip) ? 0 : texture_environment.mip_count]);
		}
		else
			uniform_set("u_iEnvironment", shader_set_uniform_i, false);
	}
	
	function apply(){
		uniform_set("u_vLightNormal", shader_set_uniform_f, [-light_normal.x, -light_normal.y, -light_normal.z]);
		uniform_set("u_vLightColor", shader_set_uniform_f, [color_get_red(light_color) / 255, color_get_green(light_color) / 255, color_get_blue(light_color) / 255]);
		uniform_set("u_fIntensity", shader_set_uniform_f, light_intensity);
	}
	
	function render_shadows(eye_id=undefined, body_array=[]){
		surface_depth_disable(false);
		if (not surface_exists(shadow_surface))
			shadow_surface = surface_create(shadow_resolution, shadow_resolution, surface_r8unorm);
		
		if (surface_get_width(shadow_surface) != shadow_resolution)
			surface_resize(shadow_surface, shadow_resolution, shadow_resolution);
			
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
			var data = {
				skeleton : U3D.RENDERING.ANIMATION.SKELETON.missing_quatpos,
				skeleton_bone_count : U3D_MAXIMUM_BONES * 2 // Only defines that we are using quatvec pairs
			}
			
			if (not is_undefined(body.animation_instance)){
				data.skeleton = body.animation_instance.get_transform_array();
				data.skeleton_bone_count = struct_names_count(body.animation_instance.skeleton);
			}
			
			body.model_instance.render_shadows(data);
		}
		shader_reset();
		matrix_set(matrix_view, mv);
		matrix_set(matrix_projection, mp);
		matrix_set(matrix_world, mw);
		surface_reset_target();
	}
	
	/// @desc	Applies the shadows to the final result by first generating a quick
	///			shadow bool sample target then multi-sampling to blend edges. 
	///	@note	The translucent pass DOESN'T render shadows, but it DOES sample 
	///			them from the opaque pass.
	function apply_shadows(eye_id, surface_in, surface_out){
		var is_translucent = Camera.get_is_translucent_stage();
		if (not casts_shadows){
			if (surface_exists(shadowbit_surface)){
				surface_free(shadowbit_surface);
				shadowbit_surface = -1;
			}
			return false;
		}
		else if (is_translucent and not surface_exists(shadow_surface))
			return false;
		
		var sw = surface_get_width(eye_id.get_camera().gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque + is_translucent]);
		var sh = surface_get_height(eye_id.get_camera().gbuffer.surfaces[$ CAMERA_GBUFFER.albedo_opaque + is_translucent]);
		
		if (surface_exists(shadowbit_surface) and surface_get_width(shadowbit_surface) != sw or surface_get_height(shadowbit_surface) != sh)
			surface_free(shadowbit_surface);
			
		if (not surface_exists(shadowbit_surface)){
			if (is_translucent)
				return false;
				
			shadowbit_surface = surface_create(sw, sh, surface_r8unorm);
		}
			
		var rep = gpu_get_texrepeat();
		gpu_set_texrepeat(false);
		surface_clear(shadowbit_surface, c_black);
		
		/// Render to shadow buffer
		/// @note	This was done as an MRT in the lighting pass, but the Windows platform
		///			was failing to write out for some reason so we switched to a separate pass.
		surface_set_target(shadowbit_surface);
		shader_set(shd_lighting_sample_shadow);
		sampler_set("u_sShadow", shadow_depth_texture);
		sampler_set("u_sDepth", eye_id.get_camera().gbuffer.textures[$ CAMERA_GBUFFER.depth_opaque + is_translucent]);
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
		gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_one, bm_one, bm_zero);	// Don't blend alpha; all lights will have the same and the HDR textures will equate to > 1
		surface_set_target(surface_out);
		shader_set(shd_lighting_apply_shadow);
		sampler_set("u_sShadow", surface_get_texture(shadowbit_surface));
		sampler_set("u_sDepth", eye_id.get_camera().gbuffer.textures[$ CAMERA_GBUFFER.depth_opaque + is_translucent]);
		uniform_set("u_vTexelSize", shader_set_uniform_f, [1.0 / surface_get_width(surface_in), 1.0 / surface_get_height(surface_in)]);
		uniform_set("u_fSampleBias", shader_set_uniform_f, [shadow_sample_bias]);
		draw_surface(surface_in, 0, 0);
		shader_reset();
		surface_reset_target();
		
		gpu_set_texrepeat(rep);
		
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