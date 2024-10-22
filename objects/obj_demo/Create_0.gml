window_set_fullscreen(true);
display_set_gui_maximise();
game_set_speed(999, gamespeed_fps);
global.mouse = {
	x : 0,
	y : 0
}
#macro gmouse global.mouse

#region ANAGLYPH PPFX
function PostProcessFXColorize(shader, color) : PostProcessFX(shader) constructor {
	#region PROPERTIES
	uniform_color = -1;
	self.color = color;
	#endregion
	
	#region METHODS
	super.register("render");
	function render(surface_out, gbuffer, buffer_width, buffer_height){
		if (not is_enabled)
			return;
		
		if (shader_current() != shader)
			shader_set(shader);
			
		if (uniform_color < 0)
			uniform_color = shader_get_uniform(shader, "u_vColor");

		if (uniform_color >= 0)
			shader_set_uniform_f(uniform_color, color_get_red(color) / 255, color_get_green(color) / 255, color_get_blue(color) / 255);
		
		super.execute("render", [surface_out, gbuffer, buffer_width, buffer_height]);
	}
	#endregion
}

ppfx_cyan = new PostProcessFXColorize(shd_colorize, make_color_rgb(0, 255, 255));
ppfx_red = new PostProcessFXColorize(shd_colorize, make_color_rgb(255, 0, 0));

ppfx_cyan.set_enabled(false);
ppfx_red.set_enabled(false);

#endregion

// camera_anaglyph = new CameraView();
// camera_anaglyph.add_post_process_effect(U3D.RENDERING.PPFX.gamma_correction);
// camera_anaglyph.add_post_process_effect(ppfx_cyan, -1);
// camera_anaglyph.set_tonemap(CAMERA_TONEMAP.none)
// camera_anaglyph.set_anchor_blend_mode(bm_add);

camera = new CameraView();
camera.add_post_process_effect(U3D.RENDERING.PPFX.fxaa);
camera.add_post_process_effect(U3D.RENDERING.PPFX.grayscale);
camera.add_post_process_effect(U3D.RENDERING.PPFX.gamma_correction);
camera.add_post_process_effect(ppfx_red, -1);
camera.set_render_stages(CAMERA_RENDER_STAGE.opaque);
U3D.RENDERING.PPFX.fxaa.set_enabled(false);
U3D.RENDERING.PPFX.grayscale.set_enabled(false);
U3D.RENDERING.PPFX.gamma_correction.set_enabled(false);
distance = 12;

instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.render_mode = RENDER_MODE.draw_gui;

obj_render_controller.add_camera(camera);

environment_map = undefined;

light_ambient = new LightAmbient();
light_ambient.light_intensity = 0.025;
light_ambient.ssao_strength = 4.0;
light_ambient.ssao_radius = 2.0;
obj_render_controller.add_light(light_ambient);

light_directional = new LightDirectional(quat(), vec(-50 * 0.25, 60 * 0.25, -70 * 0.25));
light_directional.look_at(vec());

camera.set_position(vec(distance * dcos(25), distance * 0.5, distance * dsin(25)));

body = undefined;


gpu_string = "";
var map = os_get_info();
if (os_type == os_windows)
	gpu_string = "GFX: " + map[? "video_adapter_description"];
else
	gpu_string = "GFX: " + (map[? "gl_renderer_string"] ?? "[unknown]");
	
if (string_pos("(", gpu_string) > 0)
	gpu_string = string_copy(gpu_string, 1, string_pos("(", gpu_string) - 1);

ds_map_destroy(map);

// GameMaker's gui adjustment isn't immediate; just delay GUI element spawn for a bit
alarm[0] = 60;