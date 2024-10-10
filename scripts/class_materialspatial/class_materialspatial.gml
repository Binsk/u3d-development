/// @about
/// This class defines the primary material type used to render 3D objects into
/// the world. The material comes w/ default shaders that will be used automatically
/// in the pipline, however the shaders used CAN be changed to something custom.
///
/// If a custom shader is set, it will be provided with a number of uniforms and
/// samplers that you can choose to use. Please see the details in GBUFFER UNIFORMS
/// and LIGHTING UNIFORMS sections to see what uniforms / samplers are available.
/// If your shader does not use a specified uniform it will simply not be sent to
/// the shader.

#region SHADER DETAILS
// The rendering pipeline is a deferred shading system that splits transluscent objects
// into a separate pass. This means there are two stages and two passes to the rendering
// system. The spatial material must handle all four rendering points.

// Stage 1: Building the GBuffer
// In the first stage, the primary GBuffer is built. No lighting or visual effects
// are performed in this stage. Instead, textures will be generated for all details
// required such as depth, albedo, normals, and pbr data. This stage will also handle
// any and all vertex transforms, such as skeletal animation.

// Stage 2: Lighting
// In the second stage the GBuffer is passed into a shader along with a light(s).
// This stage will be executed multiple times depending on the number of lights in
// the scene. This shader should take the light data and calculate the actual final
// render with lighting, specularity, etc. 

// Transluscency:
// Deferred rendering does not support transluscency as we can only generate one
// depth sample per pixel. The rendering pipeline makes a compromise by doing a 
// separate pass for transluscent instances where it will merge the result with
// the opaque / transparent elements. This allows us to have transluscent instances
// that properly interact with opaque instances but with the limitation of NOT
// being able to interact with other transluscent instances; only the transluscent
// pixel closest to the camera will be rendered.

// Your stage 1 shader will be provided with a uniform specifying if the pass is
// an opaque or transluscent pass. Opaque passes should only support alphas of 0
// or 1 and, in the case of an alpha of 0, the depth output should be changed to
// the z-far clip or the fragment discarded so as to allow proper 'see through'.
// Not doing this will result in rendering artifacts. The transluscent pass can
// simply render out without modification.
#endregion

/// @note	The PBR color index for roughness and metalness are defined as part
///			of the glTF spec. We are choosing to use R as the specular channel.
enum PBR_COLOR_INDEX {
	specular,		// R channel
	roughness,		// G channel
	metalness,		// B channel
}

function MaterialSpatial() : Material() constructor {
	#region PROPERTIES
	// Default shaders:
	shader_gbuffer = undefined;
	cull_mode = cull_noculling;
	
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
		pbr : [1, 1, 1], // See PBR_COLOR_INDEX for layout
		emissive : [1, 1, 1]	// ONLY applies if there is an emission texture
	}
	
	#region GBUFFER UNIFORMS
	uniform_gbuffer_sampler_albedo = -1;		// u_sAlbedo			(sampler2D)		4color material w/o lighting
	uniform_gbuffer_albedo_uv = -1;				// u_vAlbedoUV			(vec4)			UV bounds on texture page for albed
	uniform_gbuffer_albedo_scalar = -1;			// u_vAlbedo			(vec4)			color multiplier (or direct color if no texture)
	uniform_gbuffer_sampler_normal = -1;		// u_sNormal			(sampler2D)		normal direction texture in tangent space
	uniform_gbuffer_normal_uv = -1;				// u_vNormalUV			(vec4)			UV bounds on texture page for normal
	uniform_gbuffer_sampler_pbr = -1;			// u_sPBR				(sampler2D)		PBR material in [R: specular, G: roughness, B: metallic] layout
	uniform_gbuffer_pbr_uv = -1;				// u_vPBRUV				(vec4)			UV bounds on texture page for PBR
	uniform_gbuffer_pbr_scalar = -1;			// u_vPBR				(vec3)			PBR multiplier (or direct value if no nexture)
	uniform_gbuffer_sampler_emissive = -1;		// u_sEmissive			(sampler2D)		3color material for emission
	uniform_gbuffer_emissive_uv = -1;			// u_vEmissiveUV		(vec4)			UV bounds on texture page for Emissive
	uniform_gbuffer_emissive_scalar = -1;		// u_vEmissive			(vec3)			Emission multiplier (when texture exists)
	uniform_gbuffer_sampler_toggles = -1;		// u_iSamplerToggles	(int[3])		true/false for if textures are provided in [albedo, normal, PBR] layout
	uniform_gbuffer_zscalar = -1;				// u_fZScalar			(float)			distance from znear to zfar
	#endregion
	
	#region LIGHTING UNIFORMS
	#endregion
	
	#endregion
	
	#region METHODS
	/// @desc	Sets the texture for the specified label (see constructor). Texture
	///			must be a valid texture, -1, or undefined.
	function set_texture(label, texture){
		if (not is_instanceof(texture, Texture2D) and not is_undefined(texture))
			throw new Exception("invalid type, expected [Texture2D]!");
			
		label = string_lower(label);
		
		if (is_undefined(texture) or texture < 0){ // Wipe the texture if unset
			self.texture[$ label] = undefined;
			return;
		}
		
		self.texture[$ label] = {
			texture : texture,
			uv : texture_get_uvs(texture.get_texture())
		};
	}
	
	/// @desc	Return an array of shaders in their respective execution orders (see header notes)
	function get_shaders(){
		return [
			shader_gbuffer		// Stage 1
		];
	}
	
	/// @desc	Sets the shader to be used when generating the GBuffer
	function shader_set_gbuffer(shader){
		if (not shader_is_compiled(shader)){
			Exception.throw_conditional(string_ext("shader [{0}] is not compiled!", [shader_get_name(shader)]));
			return;
		}
		
		shader_gbuffer = shader;
		
		// Assign uniforms (if they don't exist they won't be sent when rendering)
		uniform_gbuffer_sampler_albedo = shader_get_sampler_index(shader, "u_sAlbedo");
		uniform_gbuffer_albedo_uv = shader_get_uniform(shader, "u_vAlbedoUV");
		uniform_gbuffer_albedo_scalar = shader_get_uniform(shader, "u_vAlbedo");
		uniform_gbuffer_sampler_normal = shader_get_sampler_index(shader, "u_sNormal");
		uniform_gbuffer_normal_uv = shader_get_uniform(shader, "u_vNormalUV");
		uniform_gbuffer_sampler_pbr = shader_get_sampler_index(shader, "u_sPBR");
		uniform_gbuffer_pbr_uv = shader_get_uniform(shader, "u_vPBRUV");
		uniform_gbuffer_pbr_scalar = shader_get_uniform(shader, "u_vPBR");
		uniform_gbuffer_sampler_emissive = shader_get_sampler_index(shader, "u_sEmissive");
		uniform_gbuffer_emissive_uv = shader_get_uniform(shader, "u_vEmissiveUV");
		uniform_gbuffer_emissive_scalar = shader_get_uniform(shader, "u_vEmissive");
		uniform_gbuffer_sampler_toggles = shader_get_uniform(shader, "u_iSamplerToggles");
		uniform_gbuffer_zscalar = shader_get_uniform(shader, "u_fZScalar");
	}
	
	function shader_set_lighting(shader){
/// @stub	Implement
	};
	
	function apply(camera_id){
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
		shader_set_uniform_i_array(uniform_gbuffer_sampler_toggles, sampler_toggles);
		
		// Send texture scalars:
		shader_set_uniform_f(uniform_gbuffer_albedo_scalar, scalar.albedo[0], scalar.albedo[1], scalar.albedo[2], scalar.albedo[3]);
		shader_set_uniform_f(uniform_gbuffer_pbr_scalar, scalar.pbr[PBR_COLOR_INDEX.specular], scalar.pbr[PBR_COLOR_INDEX.roughness], scalar.pbr[PBR_COLOR_INDEX.metalness]);
		shader_set_uniform_f(uniform_gbuffer_emissive_scalar, scalar.emissive[0], scalar.emissive[1], scalar.emissive[2]);
		
		shader_set_uniform_f(uniform_gbuffer_zscalar, camera_id.zfar - camera_id.znear);
		gpu_set_cullmode(cull_mode);
	}
	
	function duplicate(){
		var material = new MaterialSpatial();
		material.shader_set_gbuffer(shader_gbuffer);
		var texture_keys = struct_get_names(texture);
		for (var i = array_length(texture_keys) - 1; i >= 0; --i)
			material.set_texture(texture_keys[i], texture[$ texture_keys[i]]);
			
		return material;
	}
	
	#endregion
	
	#region INIT
	shader_set_gbuffer(shd_build_gbuffer);
	#endregion
}