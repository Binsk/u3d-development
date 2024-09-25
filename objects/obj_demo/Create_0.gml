vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture]);

var gltf = new GLTFBuilder("block.glb");
show_debug_message(string_ext("Mesh count: {0}", [gltf.get_mesh_count()]));
show_debug_message(string_ext("Primitive count [0]: {0}", [gltf.get_primitive_count(0)]));
box = gltf.generate_model(vformat);
material_array = gltf.generate_material_array();
for (var i = 0; i < array_length(material_array); ++i)
	box.set_material(material_array[i], i);

camera = new Camera();
body = new Body();
body.set_model(box);
instance_create_depth(0, 0, 0, obj_render_controller);
obj_render_controller.add_body(body);
obj_render_controller.add_camera(camera);