vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal]);

var gltf = new GLTFBuilder("ohelmet.gltf");
box = gltf.generate_model(vformat);

/// @stub	The generate_model() function will need to generate materials
material_array = gltf.generate_material_array();
for (var i = 0; i < array_length(material_array); ++i)
	box.set_material(material_array[i], i);

light = new LightAmbient();
light.set_casts_shadows(true);
// light.set_ssao_properties(16, 1, 5, 1.0, 2, 1);
camera = new Camera();
body = new Body();
body.set_scale(vec(4, 4, 4));
body.set_model(box);
instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.add_body(body);
obj_render_controller.add_camera(camera);
obj_render_controller.add_light(light);

distance = 10;