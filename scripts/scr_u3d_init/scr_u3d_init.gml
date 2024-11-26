/// @about
/// There are a few systems that need some initialization to make global access
/// possible right at game start. This script handles doing this in a static
/// order to prevent any conflicts.

#region DEFINE NECESSARY STATICS
// Define throw_conditional()
var foo = new Exception();
delete foo;

// Define BUILD_MAP, ANISOTROPIC_* settings
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

// Define PREPROCESS_FUNCTION
foo = new GLTFLoader();
foo.free();
delete foo;

// Load necessary fallback textures:
if (array_get_index(texturegroup_get_names(), "u3d_default") >= 0)
	texturegroup_load("u3d_default", true);
#endregion

#region MACROED SCRIPTS
// A function to return the async controller (or create it if not defined).
// Should be accessed through the macro U3D_ASYNC but is generally used internally.
function __async_instance_id(){
	with (obj_async_controller)
		return id;
	
	return instance_create_depth(0, 0, 0, obj_async_controller);
}

function __u3dgc_instance_id(){
	with (obj_u3d_gc)
		return id;
	
	return instance_create_depth(0, 0, 0, obj_u3d_gc);
}

// Determine if things must run in compatability mode due to requiring GLSL ES.
// Note that shaders are designed around simplifying for GLSL ES so if you decide
// to modify which platforms are 'compatability' you must ALSO adjust the shaders!
function __compatability_mode(){
	static RESULT = (not shader_is_compiled(shd_detect_glsles));
	return RESULT;
}
#endregion

/// Maximum number of full-data bones we can safely support (this matches w/ the spatial
/// shader bone counts). 
/// We can render twice as many partial-data bones (so long as scale is uniform).
#macro U3D_MAXIMUM_BONES (get_is_directx_pipeline() ? 64 : 80)

// A global structure that contains fallback defaults and system settings
#macro U3D global.__u3d_global_data

// Delta time, in seconds, with safety values [15..240]fps
#macro frame_delta clamp(delta_time / 1000000, 0.004, 0.067)

// Delta time, in percent, relative to a 60fps target. Useful for modifying in-
// game units designed around a 60fps limit.
#macro frame_delta_relative clamp(60 / fps, 0.25, 4.0)
#macro U3D_ASYNC __async_instance_id()	// The ID for the ASYNC controller
#macro U3D_GC __u3dgc_instance_id()		// The ID for the garbage collection controller
#macro U3D_RENDER_COMPATIBILITY_MODE __compatability_mode()	// Whether or not the system is in compatability rendering mode

/// Define U3D structure
U3D = {
	RENDERING : {
		MATERIAL : {
			missing : new MaterialSpatial(),	// Default material for when a material is missing
			blank : new MaterialSpatial()		// Default material for when material textures are undefined (e.g., color scalars only)
		},
		PPFX : { // Pre-made PostProcessingFX that can be attached to render cameras
			fxaa : new PostProcessFX(shd_fxaa),				// Fast approximate anti-aliasing
			grayscale : new PostProcessFX(shd_grayscale),	// Converts the camera to grayscale
			// Bloom does NOT work out-of-the-box and requires property tweaking. Set luminance threshold to 1.0 as a start and adjust from there
			// to change when bloom activates. Everything else effects bloom quality and range.
			bloom : new PPFXBloom(1.0, 0.45, 8, 1.25),
			fog : new PPFXFog(),
			// The skybox has no texture by default. If added to a camera, make sure to set the cubemap to a valid TextureCube or it won't render.
			skybox : new PPFXSkybox()
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
U3D.RENDERING.MATERIAL.missing.set_albedo_texture(new Texture2D(sprite_get_texture(spr_default_missing, 0)));
U3D.RENDERING.MATERIAL.missing.scalar.pbr[PBR_COLOR_INDEX.metalness] = 0;
U3D.RENDERING.MATERIAL.blank.set_albedo_texture(new Texture2D(sprite_get_texture(spr_default_white, 0)));
U3D.RENDERING.MATERIAL.blank.scalar.pbr[PBR_COLOR_INDEX.metalness] = 0;