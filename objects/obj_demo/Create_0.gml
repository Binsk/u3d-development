vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color]);
vbuffer = vertex_create_buffer();
vertex_begin(vbuffer, vformat.get_format());
vertex_position_3d(vbuffer, -2, 0, -2);
vertex_color(vbuffer, c_white, 1.0);

vertex_position_3d(vbuffer, 2, 0, -2);
vertex_color(vbuffer, c_white, 1.0);

vertex_position_3d(vbuffer, -2, 0, 2);
vertex_color(vbuffer, c_white, 1.0);

vertex_position_3d(vbuffer, 2, 0, 2);
vertex_color(vbuffer, c_white, 1.0);

vertex_end(vbuffer);

var gltf = new GLTFBuilder("block.glb");
show_debug_message(string_ext("Model count: {0}", [gltf.get_mesh_count()]));
show_debug_message(string_ext("Primitive count [0]: {0}", [gltf.get_primitive_count(0)]));
box = gltf.generate_primitive(0, 0, vformat);

camera = new Camera();
material = new MaterialSpatial();