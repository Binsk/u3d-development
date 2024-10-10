initialize_count = room_speed * 0.1; // Done to get around a GameMaker bug w/ loading textures
// vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent]);
vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal]);

// var gltf = new GLTFBuilder("block.glb");
var gltf = new GLTFBuilder("block.glb");
box = gltf.generate_model(vformat);

camera = new Camera();
body = new Body();
// body.set_scale(vec(4, 4, 4));
body.set_model(box);
instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.add_body(body);
obj_render_controller.add_camera(camera);

environment_map = new TextureCube();

light = new LightAmbient();
light.set_casts_shadows(true); // Enable SSAO
light.ssao_strength = 1.0;
light.set_environment_texture(environment_map);
light.ssao_normal_bias = 0.0
// light.ssao_multiplier = 12;
light.light_intensity = 1.0;
obj_render_controller.add_light(light);

// lightd = new LightDirectional(quat(), vec(5, 6, 7));
// lightd.look_at(vec());
// lightd.set_environment_texture(environment_map);
// obj_render_controller.add_light(lightd);

distance = 10;
var keys = struct_get_names(box.material_data);
material_array = [];
for (var i = 0; i < array_length(keys); ++i)
	array_push(material_array, box.material_data[$ keys[i]]);

camera.set_position(vec(distance * dcos(25), distance * 0.5, distance * dsin(25)));

Camera.DISPLAY_WIDTH = 1920;
Camera.DISPLAY_HEIGHT = 1080;
display_set_gui_size(1920, 1080);
obj_render_controller.render_mode = RENDER_MODE.draw_gui;

game_set_speed(999, gamespeed_fps);