/// @about
/// This demo controller spawns and controls an interface to test loading 
/// and rendering models.
/// @note	This entire demo system was thrown together very quickly for my own
///			use and was expanded on over time. As such, it is pretty sloppy and
///			may be a bit hard to follow. I hope your eyes don't bleed; I've tried
///			to clean it up at least a little.

// Good source of test models:
// https://github.com/mrdoob/three.js/tree/master/examples/models/gltf
#macro gmouse global.mouse
#region PROPERTIES
gmouse = {
	x : 0,
	y : 0
}

if (not U3D.OS.is_compatability){
	game_set_speed(9999, gamespeed_fps);
	display_reset(0, true);
}

display_debug = false;
cursor = cr_arrow;	// Updated every step for button / hover sliders

camera_orbit_distance = 12; 	// How far away from the model to orbit
camera_rotation_offset = 0;		// Used to smoothly start / stop camera rotation since it is time-based
camera_rotation_last = current_time;
camera_is_rotating = true;		// Whether or not the camera is rotating (shouldn't be toggled directly)

primary_button = noone;			// The button that loaded our primary skeletal model for attaching things to (buttons contain model body references)
environment_map = undefined;	// Our test environment map for reflections
body_floor = undefined;			// Body used when rendering the demo floor
body_floor_y = 0;				// A custom tracked y-value to make sure the floor stays below models

material_count = 0;				// Counter values for displaying model info in the GUI
model_count = 0;
mesh_count = 0;
primitive_count = 0;

animation_loop = true;		// Animation properties we will apply to the currently animated models (all global)
animation_smooth = true;
animation_speed = 1.0;
animation_freq = 0.033;
import_textures = true;
import_lights = false;
apply_transforms = true;

error_array = [];			// Used to catch several model loading errors w/ incompatible models; displays these on-screen
error_time = 0;

slider_ay = 0;				// Slider offset used when dynamically spawning 'scaling' model sliders
model_scale_slider_array = [];	// Array of slider instances spawned to scale models
#endregion

#region METHODS
/// @desc	Recounts the number of resources currently loaded. This is slow and
///			relies on debugging functions.
function update_data_count(){
	material_count = get_ref_instance_count(Material);
	model_count = get_ref_instance_count(Model);
	mesh_count = get_ref_instance_count(Mesh);
	primitive_count = get_ref_instance_count(Primitive);
}

/// @desc	Pushes a new error to the stack and resets the display timer.
function push_error(message){
	error_time = current_time;
	array_push(error_array, message);
}
#endregion

#region INIT
// Init basic window / game settings:
if (not U3D.OS.is_compatability and current_time < 1000)
	window_set_fullscreen(true);
	
display_set_gui_maximise();
game_set_speed(9999, gamespeed_fps);

// We want to be able to display debugging wireframes:
Primitive.GENERATE_WIREFRAMES = true;

// Spawn necessary controllers:
instance_create_depth(0, 0, 0, obj_animation_controller);	// Allow auto-handling animation updates
instance_create_depth(0, 0, 0, obj_render_controller);		// Allow auto-handling rendering updates

obj_render_controller.set_render_mode(RENDER_MODE.draw_gui);	// Set to display in GUI just for simplicity in rendering resolution

// Create our camera:
camera = new CameraView();	// CameraView auto-renders to screen; defaults to full screen
camera.get_eye().set_zfar(128);	// Change zfar since the default is a bit far out for this scene

	// Here we attach post-processing effects. The larger the number, the earlier the effect gets processed:
camera.add_ppfx(U3D.RENDERING.PPFX.fog, 3);		// Adds fog to the clipping plane; we set up the fog to turn yellow the fade the alpha to 0
camera.add_ppfx(U3D.RENDERING.PPFX.skybox, 2);	// Renders a sky-box 'under' the render so it peaks through any spots where alpha < 1
camera.add_ppfx(U3D.RENDERING.PPFX.bloom, 1);	// Apply bloom on top of the render
camera.add_ppfx(U3D.RENDERING.PPFX.fxaa);		// Add some post-processing effects on top of the bloom
camera.add_ppfx(U3D.RENDERING.PPFX.grayscale);	// Set things to grayscale (just a way to test the simplest of PPFX)
U3D.RENDERING.PPFX.fxaa.set_enabled(false);					// Disable the post-processing; it can be toggled through the interface
U3D.RENDERING.PPFX.grayscale.set_enabled(false);
U3D.RENDERING.PPFX.bloom.set_enabled(false);
U3D.RENDERING.PPFX.bloom.set_luminance_threshold(0.0);
U3D.RENDERING.PPFX.fog.set_color(c_yellow, 0.0);	// As fog hits, blend to yellow but also fade out alpha into background. Yellow is just to let us know it is at the edge of the clipping plane.
U3D.RENDERING.PPFX.skybox.set_enabled(false);		// We enable along w/ environmental mapping
Texture2D.ANISOTROPIC_OVERRIDE_LINEAR = true;		// Switch any imported linear filtering texture settings to anisotropic (glTF doesn't support it in the spec)

camera.set_render_stages(CAMERA_RENDER_STAGE.opaque);		// Only render opaque pass by default; translucent can be enabled through the interface
camera.set_position(vec(camera_orbit_distance * dcos(25), camera_orbit_distance * 0.5, camera_orbit_distance * dsin(25)));

// camera.set_render_stages(CAMERA_RENDER_STAGE.mixed);
obj_render_controller.add_camera(camera);					// Assign our camera to be managed by the rendering system

// Create our ambient light:
light_ambient = new LightAmbient();
light_ambient.light_intensity = 0.1;
light_ambient.ssao_strength = 4.0;	// SSAO properties will heavily depend on the project; these work fairly well for this setup
light_ambient.ssao_radius = 2.0;
obj_render_controller.add_light(light_ambient);	// Add the light to the rendering system so it is processed

// Create our directional light:
	// Even though directional, we create it a ways out for shadow mapping. Lighting doesn't care about position but
	// shadow mapping renders from the light position.
light_directional = new LightDirectional(quat(), vec(50 * 0.25, 60 * 0.25, 70 * 0.25));
light_directional.look_at(vec()); // Specify to look at the center point where the model will spawn
light_directional.shadow_world_units = 24;
light_directional.shadow_sample_bias = 0.000001;	// Depends on view distance; but discards samples based on depth difference (helps remove haloing)
light_directional.shadow_bias = 0.00005;
light_directional.set_intensity(2.0);

// Define render size (will be auto-updated w/ the GUI)
render_width = display_get_gui_width();
render_height = display_get_gui_height();

// Get information about the GPU name:
gpu_string = "";
var map = os_get_info();
if (os_type == os_windows)
	gpu_string = "GFX: " + map[? "video_adapter_description"];
else
	gpu_string = "GFX: " + (map[? "gl_renderer_string"] ?? "[unknown]");
	
if (string_pos("(", gpu_string) > 0)
	gpu_string = string_copy(gpu_string, 1, string_pos("(", gpu_string) - 1);

ds_map_destroy(map);

// Track texture memory freeing and such:
U3D_GC.signaler.add_signal("cleaned_ref", new Callable(id, update_data_count));

// GameMaker's gui adjustment isn't immediate; just delay GUI element spawn for a bit.
// Had issues w/ length of time in the VM so 60 frames is enough to give it setup time.
if (current_time < 2000)
	alarm[0] = 60;
else
	alarm[0] = 1;
#endregion