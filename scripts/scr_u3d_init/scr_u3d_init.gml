/// @about
/// There are a few systems that need some initialization to make global access
/// possible right at game start. This script handles doing this in a static
/// order to prevent any conflicts.

#region DEFINE NECESSARY STATICS
// Define throw_conditional()
var foo = new Exception();
delete foo;

// Define BUILD_MAP
foo = new TextureCube();
foo.free();
delete foo;

// Define get_format_instance()
foo = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent]);
foo.free();
delete foo;

// Define GENERATE_WIREFRAMES
foo = new Primitive(VertexFormat.get_format_instance([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent]));
foo.free();
delete foo;

// Define relevant LERP functions:
foo = new AnimationChannelPosition();
foo.free();
delete foo;
foo = new AnimationChannelRotation();
foo.free();
delete foo;
foo = new AnimationChannelScale();
foo.free();
delete foo;

// Load necessary fallback textures:
if (array_get_index(texturegroup_get_names(), "u3d_default") >= 0)
	texturegroup_load("u3d_default", true);
#endregion

/// Maximum number of full-data bones we can safely support (this matches w/ the spatial
/// shader bone counts). 
/// We can render twice as many partial-data bones (so long as scale is uniform).
#macro U3D_MAXIMUM_BONES (get_is_directx_pipeline() ? 64 : 80)

// A global structure that contains fallback defaults and system settings
#macro U3D global.__u3d_global_data

// Delta time, in seconds, with safety values.
#macro frame_delta clamp(delta_time / 1000000, 0.004, 0.067)

// Delta time, in percent, relative to a 60fps target. Helpful if the system was
// designed around 60fps and needs later adjustment.
#macro frame_delta_relative clamp(60 / fps, 0.25, 4.0)

/// Define U3D structure
U3D = {
	RENDERING : {
		MATERIAL : {
			missing : new MaterialSpatial(),	// Default material for when a material is missing
			blank : new MaterialSpatial()		// Default material for when no material is specified
		},
		PPFX : { // Pre-made PostProcessingFX that can be attached to render cameras
			fxaa : new PostProcessFX(shd_fxaa),				// FXAA anti-aliasing
			grayscale : new PostProcessFX(shd_grayscale),	// Turns the output into grayscale
			gamma_correction : new PostProcessFX(shd_gamma_correction)	// Does basic gamma correction; useful if we want to do it manually outside the tonemap
		},
		ANIMATION : {
			SKELETON : {
				missing_matrices : array_flatten(array_create(U3D_MAXIMUM_BONES, matrix_build_identity())),	// Default skeleton for full-data bones
				missing_quatpos : array_flatten(array_create(U3D_MAXIMUM_BONES * 2, [0, 0, 0, 1, 0, 0, 0, 0]))	// Default skeleton for partial-data bones
			}
		}
	},
	MEMORY : {}	// Used to hold data caches and garbage-collect dynamically generated resources
}

// Define 'missing material' texture:
U3D.RENDERING.MATERIAL.missing.set_texture("albedo", new Texture2D(sprite_get_texture(spr_default_missing, 0)));
U3D.RENDERING.MATERIAL.missing.scalar.pbr[PBR_COLOR_INDEX.metalness] = 0;
U3D.RENDERING.MATERIAL.blank.set_texture("albedo", new Texture2D(sprite_get_texture(spr_default_white, 0)));
U3D.RENDERING.MATERIAL.blank.scalar.pbr[PBR_COLOR_INDEX.metalness] = 0;