/// @about
/// This class defines the primary material type used to render 3D objects into
/// the world. The material comes w/ a default shader that will be used automatically
/// in the pipline, however the shader used CAN be changed to something custom.
///
/// If a custom shader is set, it will be provided with a number of uniforms and
/// samplers that you can choose to use. Please see the details in GBUFFER UNIFORMS
/// and LIGHTING UNIFORMS sections to see what uniforms / samplers are available.
/// If your shader does not use a specified uniform it will simply not be sent to
/// the shader.

#region SHADER DETAILS
// The rendering pipeline is a deferred shading system that splits transluscent objects
// into a separate pass.

// Building the GBuffer
// This material is used when the primary GBuffer is built. No lighting or visual effects
// are performed in this stage. Instead, textures will be generated for all details
// required such as depth, albedo, normals, pbr, and emissive data. This stage will also handle
// any and all vertex transforms, such as skeletal animation.

// Transluscency:
// Deferred rendering does not support transluscency as we can only generate one
// depth sample per pixel. The rendering pipeline makes a compromise by doing a 
// separate pass for translucent instances where it will merge the result with
// the opaque / transparent elements. This allows us to have transluscent instances
// that properly interact with opaque instances but with the limitation of NOT
// being able to interact with other translucent instances; only the translucent
// pixel closest to the camera will be rendered.

// Your shader will be provided with a uniform specifying if the pass is
// an opaque or transluscent pass. Opaque passes should only support alphas of 0
// or 1 and, in the case of an alpha of 0, the depth output should be changed to
// the z-far clip or the fragment discarded so as to allow proper 'see through'.
// Not doing this will result in rendering artifacts. The transluscent pass can
// simply render out without modification, including the depth buffer.
#endregion

/// @note	The PBR color index for roughness and metalness are defined as part
///			of the glTF spec. We are choosing to use R as the specular channel.
enum PBR_COLOR_INDEX {
	specular,		// R channel	(Note: Not currently used, have some math bits to figure out)
	roughness,		// G channel
	metalness,		// B channel
}

function MaterialSpatial() : Material() constructor {
	#region PROPERTIES
	shader_gbuffer = undefined;
	cull_mode = cull_noculling;
	shadow_cull_mode = cull_noculling;
	render_stage = CAMERA_RENDER_STAGE.opaque;
	alpha_cutoff = 0.5;		// Opaque render will step the alpha from 0 to 1 based around this cutoff
	
	// Textures
	texture = {
		albedo : undefined,
		normal : undefined,
		pbr : undefined,
		emissive : undefined
	};
	
	/// @note	scalar albedo is multiplicative, however if no texture exists and no vertex
	///			color exists, it will be used as-is for the color in LINEAR space! Vertex
	///			colors act similarly and are ALSO in LINEAR space! Albedo textures are
	///			assumed to be in sRGB space and will be converted to LINEAR for lighting
	///			before everything is converted back to sRGB at the end.
	scalar = {
		albedo : [1, 1, 1, 1],
		pbr : [1, 1, 1],		// See PBR_COLOR_INDEX for layout
		emissive : [1, 1, 1]	// ONLY applies if there is an emission texture
	}
	
	#region GBUFFER UNIFORMS
	// The following are the uniforms that are available toy our spatial shader. If a uniform is
	// not specified in your shader then it will not be sent.
	//												UNIFORM					TYPE			DESCRIPTION
	uniform_gbuffer_sampler_albedo = -1;		// u_sAlbedo			(sampler2D)		4color material w/o lighting
	uniform_gbuffer_albedo_uv = -1;				// u_vAlbedoUV			(vec4)			UV bounds on texture page for albedo
												// u_vAlbedo			(vec4)			color multiplier (or direct color if no texture)
	uniform_gbuffer_sampler_normal = -1;		// u_sNormal			(sampler2D)		normal direction texture in tangent space
	uniform_gbuffer_normal_uv = -1;				// u_vNormalUV			(vec4)			UV bounds on texture page for normal
	uniform_gbuffer_sampler_pbr = -1;			// u_sPBR				(sampler2D)		PBR material in [R: specular, G: roughness, B: metallic] layout
	uniform_gbuffer_pbr_uv = -1;				// u_vPBRUV				(vec4)			UV bounds on texture page for PBR
												// u_vPBR				(vec3)			PBR multiplier (or direct value if no nexture)
	uniform_gbuffer_sampler_emissive = -1;		// u_sEmissive			(sampler2D)		3color material for emission
	uniform_gbuffer_emissive_uv = -1;			// u_vEmissiveUV		(vec4)			UV bounds on texture page for Emissive
												// u_vEmissive			(vec3)			Emission multiplier (when texture exists)
												// u_iSamplerToggles	(int[3])		true/false for if textures are provided in [albedo, normal, PBR] layout
												// u_fAlphaCutoff		(float)			opaque render sets alpha=0 if < cutoff and 1 if >=
												// u_iTranslucent		(int)			whether or not it is a translucent pass
												// u_mBone				(mat4[80])		array of bone transform matrices (up to 80); NOTE: uniform set by mesh, not material!
	#endregion
	#endregion
	
	#region METHODS
	/// @desc	Sets the albedo factor for the material. This value gets multiplied
	///			against a model's vertex and albedo texture values.
	/// @note	If the material renders in the 'opaque' render stage then the alpha
	///			will be compared to the alpha_cutoff and set to 0 or 1 when rendering.
	function set_albedo_factor(color, alpha){
		scalar.albedo = [
			color_get_red(color) / 255,
			color_get_green(color) / 255,
			color_get_blue(color) / 255,
			alpha
		];
	}
	
	/// @desc	Sets the metalness factor for the material. If no texture is specified
	///			then this is the material metalness. If a texture is defined then 
	///			it will be multiplied by this value.
	/// @param	{real}	metalness		metalness between [0..1]
	function set_metalness_factor(value){
		scalar.pbr[PBR_COLOR_INDEX.metalness] = clamp(value, 0, 1);
	}
	
	/// @desc	Sets the roughness factor for the material. If no texture is specified
	///			then this is the material roughness. If a texture is defined then 
	///			it will be multiplied by this value.
	/// @param	{real}	roughness		roughness between [0..1]
	function set_roughness_factor(value){
		scalar.pbr[PBR_COLOR_INDEX.roughness] = clamp(value, 0, 1);
	}
	
	/// @desc	Sets the emissive factor for the material. Emission is only activated
	///			if there is a valid emissive texture which will be multiplied by this value.
	function set_emissive_factor(color){
		scalar.emissive = [
			color_get_red(color) / 255,
			color_get_green(color) / 255,
			color_get_blue(color) / 255
		]
	}
	
	/// @desc	Sets the texture for the specified label (see constructor). Texture
	///			must be a valid Texture2D or undefined.
	function set_texture(label, texture){
		if (not is_instanceof(texture, Texture2D) and not is_undefined(texture))
			throw new Exception("invalid type, expected [Texture2D]!");
			
		label = string_lower(label);
		
		if (is_undefined(texture)){ // Wipe the texture if unset
			if (not is_undefined(self.texture[$ label]))
				remove_child_ref(texture[$ label].texture);
				
			self.texture[$ label] = undefined;
			return;
		}
		
		add_child_ref(texture);
		
		self.texture[$ label] = {
			texture : texture,
			uv : texture_get_uvs(texture.get_texture())
		};
	}
	
	/// @desc	Sets the Texture2D to use for the albedo texture, or undefined.
	/// @param	{Texture2D}	texture
	function set_albedo_texture(texture){
		set_texture("albedo", texture);
	}
	
	/// @desc	Sets the Texture2D to use for the normal texture, or undefined.
	/// @param	{Texture2D}	texture
	function set_normal_texture(texture){
		set_texture("normal", texture);
	}
	
	/// @desc	Sets the Texture2D to use for the pbr texture, or undefined.
	/// @param	{Texture2D}	texture
	function set_pbr_texture(texture){
		set_texture("pbr", texture);
	}
	
	/// @desc	Sets the Texture2D to use for the emissive texture, or undefined.
	/// @param	{Texture2D}	texture
	function set_emissive_texture(texture){
		set_texture("emissive", texture);
	}
	
	/// @desc	Sets the shader to be used when generating the GBuffer.
	function set_shader(shader){
		if (not shader_is_compiled(shader)){
			Exception.throw_conditional(string_ext("shader [{0}] is not compiled!", [shader_get_name(shader)]));
			return;
		}
		
		shader_gbuffer = shader;
		
		// Assign uniforms (if they don't exist they won't be sent when rendering)
		uniform_gbuffer_sampler_albedo = shader_get_sampler_index(shader, "u_sAlbedo");
		uniform_gbuffer_albedo_uv = shader_get_uniform(shader, "u_vAlbedoUV");
		uniform_gbuffer_sampler_normal = shader_get_sampler_index(shader, "u_sNormal");
		uniform_gbuffer_normal_uv = shader_get_uniform(shader, "u_vNormalUV");
		uniform_gbuffer_sampler_pbr = shader_get_sampler_index(shader, "u_sPBR");
		uniform_gbuffer_pbr_uv = shader_get_uniform(shader, "u_vPBRUV");
		uniform_gbuffer_sampler_emissive = shader_get_sampler_index(shader, "u_sEmissive");
		uniform_gbuffer_emissive_uv = shader_get_uniform(shader, "u_vEmissiveUV");
	}
	
	/// @desc	Returns the color component of the albedo factor.
	function get_albedo_color_factor(){
		return make_color_rgb(scalar.albedo[0] * 255, scalar.albedo[1] * 255, scalar.albedo[2] * 255);
	}
	
	/// @desc	Returns the alpha component of the albedo factor.
	function get_albedo_alpha_factor(){
		return scalar.albedo[3];
	}
	
	/// @desc	Returns the currently set metalness factor for this material.
	function get_metalness_factor(){
		return scalar.pbr[PBR_COLOR_INDEX.metalness];
	}
	
	/// @desc	Returns the currently set roughness factor for this material.
	function get_roughness_factor(){
		return scalar.pbr[PBR_COLOR_INDEX.roughness];
	}
	
	/// @desc	Returns the currently set 
	function get_emissive_factor(){
		return make_color_rgb(scalar.emissive[0] * 255, scalar.emissive[1] * 255, scalar.emissive[2] * 255);
	}
	
	/// @desc	Returns the current shader set for this material.
	function get_shader(){
		return shader_gbuffer;
	}
	
	function apply(camera_id, is_translucent=false){
		if (shader_current() != shader_gbuffer)
			shader_set(shader_gbuffer);
		
		// Send textures
		var sampler_toggles = [0, 0, 0, 0];
		if (uniform_gbuffer_sampler_albedo >= 0 and not is_undefined(texture[$ "albedo"])){
			texture_set_stage(uniform_gbuffer_sampler_albedo, texture.albedo.texture.get_texture());
			shader_set_uniform_f(uniform_gbuffer_albedo_uv, texture.albedo.uv[0], texture.albedo.uv[1], texture.albedo.uv[2], texture.albedo.uv[3]);
			sampler_toggles[0] = 1;
		}
		
		if (uniform_gbuffer_sampler_normal >= 0 and not is_undefined(texture[$ "normal"])){
			texture_set_stage(uniform_gbuffer_sampler_normal, texture.normal.texture.get_texture());
			shader_set_uniform_f(uniform_gbuffer_normal_uv, texture.normal.uv[0], texture.normal.uv[1], texture.normal.uv[2], texture.normal.uv[3]);
			sampler_toggles[1] = 1;
		}
		
		if (uniform_gbuffer_sampler_pbr >= 0 and not is_undefined(texture[$ "pbr"])){
			texture_set_stage(uniform_gbuffer_sampler_pbr, texture.pbr.texture.get_texture());
			shader_set_uniform_f(uniform_gbuffer_pbr_uv, texture.pbr.uv[0], texture.pbr.uv[1], texture.pbr.uv[2], texture.pbr.uv[3]);
			sampler_toggles[2] = 1;
		}
		
		if (uniform_gbuffer_sampler_emissive >= 0 and not is_undefined(texture[$ "emissive"])){
			texture_set_stage(uniform_gbuffer_sampler_emissive, texture.emissive.texture.get_texture());
			shader_set_uniform_f(uniform_gbuffer_emissive_uv, texture.emissive.uv[0], texture.emissive.uv[1], texture.emissive.uv[2], texture.emissive.uv[3]);
			sampler_toggles[3] = 1;
		}

		// Set samplers; if no texture then the values are used directly otherwise they are multiplied
		uniform_set("u_iSamplerToggles", shader_set_uniform_i_array, [sampler_toggles]);
		
		// Send texture scalars:
		uniform_set("u_vAlbedo", shader_set_uniform_f, [scalar.albedo[0], scalar.albedo[1], scalar.albedo[2], scalar.albedo[3]]);
		uniform_set("u_vPBR", shader_set_uniform_f, [scalar.pbr[PBR_COLOR_INDEX.specular], scalar.pbr[PBR_COLOR_INDEX.roughness], scalar.pbr[PBR_COLOR_INDEX.metalness]]);
		uniform_set("u_vEmissive", shader_set_uniform_f, [scalar.emissive[0], scalar.emissive[1], scalar.emissive[2]]);
		
		uniform_set("u_fAlphaCutoff", shader_set_uniform_f, alpha_cutoff);
		uniform_set("u_iTranslucent", shader_set_uniform_i, is_translucent);
		
		gpu_set_cullmode(cull_mode);
	}
	
	function apply_shadow(){
		var shader = shader_current();
		if (shader < 0)
			return;
	
		var albedo_texture = (is_undefined(texture[$ "albedo"]) ? sprite_get_texture(spr_default_white, 0) : texture.albedo.texture.get_texture());
		texture_set_stage(shader_get_sampler_index(shader, "u_sAlbedo"), albedo_texture);
		uniform_set("u_sAlphaCutoff", shader_set_uniform_f, alpha_cutoff);
		
		gpu_set_cullmode(shadow_cull_mode);
	}
	
	function duplicate(){
		var material = new MaterialSpatial();
		material.shader_set_gbuffer(shader_gbuffer);
		var texture_keys = struct_get_names(texture);
		for (var i = array_length(texture_keys) - 1; i >= 0; --i)
			material.set_texture(texture_keys[i], texture[$ texture_keys[i]]);
			
		return material;
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		texture_keys = {};
	}
	#endregion
	
	#region INIT
	set_shader(shd_build_gbuffer);
	#endregion
}