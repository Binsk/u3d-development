/// @about
/// This class defines the primary material type used to render 3D objects into
/// the world. The material comes w/ default shaders that will be used automatically
/// in the pipline, however the shaders used CAN be changed to something custom.
///
/// If a custom shader is set, it will be provided with a number of uniforms and
/// samplers that you can choose to use. Please see the details in the FRAGMENT
/// and VERTEX portions below to help you design your shader.

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

#region FRAGMENT DETAILS
#endregion

#region VERTEX DETAILS
#endregion

function MaterialSpatial() : Material() constructor {
	#region PROPERTIES
	// Default shaders:
	shader_gbuffer = shd_build_gbuffer;
	shader_lighting = undefined;
	#endregion
	
	#region METHODS
	/// @desc	Return an array of shaders in their respective execution orders (see header notes)
	function get_shaders(){
		return [
			shader_gbuffer,		// Stage 1
			shader_lighting		// Stage 2
		];
	}
	#endregion
	
	#region INIT
	#endregion
}