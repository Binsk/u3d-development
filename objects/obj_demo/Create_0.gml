vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal]);

var gltf = new GLTFBuilder("block.glb");
box = gltf.generate_model(vformat);
/// @stub	The generate_model() function will need to generate materials
material_array = gltf.generate_material_array();
for (var i = 0; i < array_length(material_array); ++i)
	box.set_material(material_array[i], i);

light = new LightAmbient();
camera = new Camera();
body = new Body();
body.set_model(box);
instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.add_body(body);
obj_render_controller.add_camera(camera);
obj_render_controller.add_light(light);

distance = 10;