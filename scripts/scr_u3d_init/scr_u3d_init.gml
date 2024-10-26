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

foo = new AnimationChannelPosition(-1);
foo.free();
delete foo;
foo = new AnimationChannelRotation(-1);
foo.free();
delete foo;
foo = new AnimationChannelScale(-1);
foo.free();
delete foo;

texturegroup_load("U3DDefaults", true);
#endregion

// This structure holds a number of defaults and fallback values. The system 
// relies on this structure but it can also be accessed / modified manually if
// needed.
global.__u3d_global_data = {
	RENDERING : {
		MATERIAL : {
			missing : new MaterialSpatial()	// Default material for when a material is missing
		},
		PPFX : { // Pre-made PostProcessingFX that can be attached to render cameras
			fxaa : new PostProcessFX(shd_fxaa),				// FXAA anti-aliasing
			grayscale : new PostProcessFX(shd_grayscale),	// Turns the output into grayscale
			gamma_correction : new PostProcessFX(shd_gamma_correction)	// Does basic gamma correction; useful if we want to do it manually
		}
	},
	MEMORY : {}	// Used to hold data caches and garbage-collect dynamically generated resources
}

#macro U3D global.__u3d_global_data

// Delta time, in seconds, with safety values.
#macro frame_delta clamp(delta_time / 1000000, 0.004, 0.067)

// Delta time, in percent, relative to a 60fps target. Helpful if the system was
// designed around 60fps and needs later adjustment.
#macro frame_delta_relative clamp(60 / fps, 0.25, 4.0)

// Define 'missing material' texture:
U3D.RENDERING.MATERIAL.missing.set_texture("albedo", new Texture2D(sprite_get_texture(spr_missing_texture, 0)));
U3D.RENDERING.MATERIAL.missing.scalar.pbr[PBR_COLOR_INDEX.metalness] = 0;