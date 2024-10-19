window_set_fullscreen(true);
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

vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent]);

camera_anaglyph = new Camera();
camera_anaglyph.add_post_process_effect(U3D.RENDERING.PPFX.gamma_correction);
camera_anaglyph.add_post_process_effect(ppfx_cyan, -1);
camera_anaglyph.set_tonemap(CAMERA_TONEMAP.none)
camera_anaglyph.set_anchor_blend_mode(bm_add);

camera = new Camera();
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
Camera.DISPLAY_WIDTH = 1920;
Camera.DISPLAY_HEIGHT = 1080;

display_set_gui_size(Camera.DISPLAY_WIDTH, Camera.DISPLAY_HEIGHT);
obj_render_controller.render_mode = RENDER_MODE.draw_gui;

game_set_speed(999, gamespeed_fps);

// Generate GUI:
	// Scane model files:
var file = file_find_first("*.glb", fa_none);
var inst;
var ax = 1920 - 12 - 256;
while (file != ""){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
file_find_close();

file = file_find_first("*.gltf", fa_none);
while (file != ""){
	inst = instance_create_depth(ax, 12 + instance_number(obj_button) * 44, 0, obj_button);
	inst.text = file;
	file = file_find_next();
}
 
inst = instance_create_depth(ax, 1080 - 12 - 44, 0, obj_button);
inst.is_model_button = false;
inst.text = "Exit";
inst.signaler.add_signal("pressed", new Callable(id, game_end));
// Directional Light:
var subinst;
ax = 12;
var ay = 1080 - 12 - 24;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "Directional Light";
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_directional);
	else
		obj_render_controller.add_light(obj_demo.light_directional);
});

subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows";
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_directional.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, subinst);

subinst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
subinst.text = "Environment";
subinst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_demo.light_directional.set_environment_texture(undefined);
	else{
		if (is_undefined(obj_demo.environment_map))
			obj_demo.environment_map = new TextureCubeMip(sprite_get_texture(spr_default_environment_cube, 1), 1024, 2, true);
		
		obj_demo.light_directional.set_environment_texture(obj_demo.environment_map);
	}
});
array_push(inst.child_elements, subinst);

ay -= 36;

// Ambient Light
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "Ambient Light";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_render_controller.remove_light(obj_demo.light_ambient);
	else
		obj_render_controller.add_light(obj_demo.light_ambient);
});
subinst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
subinst.text = "Shadows (SSAO)";
subinst.signaler.add_signal("checked", function(is_checked){
	obj_demo.light_ambient.set_casts_shadows(is_checked);
});
array_push(inst.child_elements, subinst);

subinst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
subinst.text = "Environment";
subinst.signaler.add_signal("checked", function(is_checked){
	if (not is_checked)
		obj_demo.light_ambient.set_environment_texture(undefined);
	else{
		if (is_undefined(obj_demo.environment_map))
			obj_demo.environment_map = new TextureCubeMip(sprite_get_texture(spr_default_environment_cube, 1), 1024, 2, true);
		
		obj_demo.light_ambient.set_environment_texture(obj_demo.environment_map);
	}
});
array_push(inst.child_elements, subinst);

ay -= 36;
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text ="Opaque Pass";
inst.is_checked = true;
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked)
		obj_demo.camera.render_stages |= CAMERA_RENDER_STAGE.opaque;
	else
		obj_demo.camera.render_stages &= ~CAMERA_RENDER_STAGE.opaque;
});

inst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
inst.text ="Translucent Pass";
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked)
		obj_demo.camera.render_stages |= CAMERA_RENDER_STAGE.translucent;
	else
		obj_demo.camera.render_stages &= ~CAMERA_RENDER_STAGE.translucent;
});

ay -= 36
inst = instance_create_depth(ax, ay, 0, obj_checkbox);
inst.text = "FXAA";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	U3D.RENDERING.PPFX.fxaa.set_enabled(is_checked);
});

inst = instance_create_depth(ax + 256, ay, 0, obj_checkbox);
inst.text = "Grayscale";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	U3D.RENDERING.PPFX.grayscale.set_enabled(is_checked);
});

inst = instance_create_depth(ax + 512, ay, 0, obj_checkbox);
inst.text = "Stereoscopy";
inst.is_checked = false;
inst.signaler.add_signal("checked", function(is_checked){
	if (is_checked){
		obj_demo.ppfx_red.set_enabled(true);
		obj_demo.ppfx_cyan.set_enabled(true);
		obj_render_controller.add_camera(obj_demo.camera_anaglyph);
		obj_demo.camera.set_anchor_blend_mode(bm_add);
		U3D.RENDERING.PPFX.gamma_correction.set_enabled(true);
		obj_demo.camera.set_tonemap(CAMERA_TONEMAP.none);
	}
	else {
		obj_demo.ppfx_cyan.set_enabled(false);
		obj_demo.ppfx_red.set_enabled(false);
		obj_render_controller.remove_camera(obj_demo.camera_anaglyph);
		obj_demo.camera.set_anchor_blend_mode(bm_normal);
		U3D.RENDERING.PPFX.gamma_correction.set_enabled(false);
		obj_demo.camera.set_tonemap(CAMERA_TONEMAP.simple);
	}
});