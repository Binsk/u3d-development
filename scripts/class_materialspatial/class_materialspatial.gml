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

function MaterialSpatial() : Material() constructor {
	#region PROPERTIES
	// Default shaders:
	shader_gbuffer = undefined;
	shader_lighting = undefined;
	
	// Textures
	texture = {
		albedo : undefined,
		normal : undefined,
		pbr : undefined
	};
	
	scalar = {
		albedo : [1, 1, 1, 1]
	}
	
	#region GBUFFER UNIFORMS
	uniform_gbuffer_sampler_albedo = -1;		// u_sAlbedo		(sampler2D)
	uniform_gbuffer_albedo_uv = -1;				// u_vAlbedoUV		(vec4)
	uniform_gbuffer_albedo_scalar = -1;			// u_vAlbedo		(vec4)
	uniform_gbuffer_sampler_normal = -1;		// u_sNormal		(sampler2D)
	uniform_gbuffer_normal_uv = -1;				// u_vNormalUV		(vec4)
	uniform_gbuffer_sampler_pbr = -1;			// u_sPBR			(sampler2D)
	uniform_gbuffer_pbr_uv = -1;				// u_vPBRUV			(vec4)
	#endregion
	
	#region LIGHTING UNIFORMS
	#endregion
	
	#endregion
	
	#region METHODS
	/// @desc	Sets the texture for the specified label (see constructor). Texture
	///			must be a valid texture, -1, or undefined.
	function set_texture(label, texture){
		label = string_lower(label);
		
		if (is_undefined(texture) or texture < 0){ // Wipe the texture if unset
			self.texture[$ label] = undefined;
			return;
		}

		self.texture[$ label] = {
			texture : texture,
			uv : texture_get_uvs(texture)
		};
	}
	
	/// @desc	Return an array of shaders in their respective execution orders (see header notes)
	function get_shaders(){
		return [
			shader_gbuffer,		// Stage 1
			shader_lighting		// Stage 2
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
	}
	
	function shader_set_lighting(shader){
/// @stub	Implement
	};
	
	function apply(render_stage){
		if (render_stage == RENDER_STAGE.build_gbuffer){
			if (shader_current() != shader_gbuffer)
				shader_set(shader_gbuffer);
			
			// Send textures
			if (uniform_gbuffer_sampler_albedo >= 0 and not is_undefined(texture[$ "albedo"])){
				texture_set_stage(uniform_gbuffer_sampler_albedo, texture.albedo.texture);
				shader_set_uniform_f(uniform_gbuffer_albedo_uv, texture.albedo.uv[0], texture.albedo.uv[1], texture.albedo.uv[2], texture.albedo.uv[3]);
			}
			
			if (uniform_gbuffer_sampler_normal >= 0 and not is_undefined(texture[$ "normal"])){
				texture_set_stage(uniform_gbuffer_sampler_normal, texture.normal.texture);
				shader_set_uniform_f(uniform_gbuffer_normal_uv, texture.normal.uv[0], texture.normal.uv[1], texture.normal.uv[2], texture.normal.uv[3]);
			}
			
			if (uniform_gbuffer_sampler_pbr >= 0 and not is_undefined(texture[$ "pbr"])){
				texture_set_stage(uniform_gbuffer_sampler_pbr, texture.pbr.texture);
				shader_set_uniform_f(uniform_gbuffer_pbr_uv, texture.pbr.uv[0], texture.pbr.uv[1], texture.pbr.uv[2], texture.pbr.uv[3]);
			}
			
			// Send PBR scalars:
			shader_set_uniform_f(uniform_gbuffer_albedo_scalar, scalar.albedo[0], scalar.albedo[1], scalar.albedo[2], scalar.albedo[3]);
			
			return;
		}
		
		if (render_stage == RENDER_STAGE.light_pass){
			if (shader_current() != shader_lighting)
				shader_set(shader_lighting);
			
			return;
		}
	}
	
	function duplicate(){
		var material = new MaterialSpatial();
		material.shader_set_gbuffer(shader_gbuffer);
		material.shader_set_lighting(shader_lighting);
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