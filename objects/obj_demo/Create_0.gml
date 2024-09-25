vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture]);

var gltf = new GLTFBuilder("block.glb");
show_debug_message(string_ext("Mesh count: {0}", [gltf.get_mesh_count()]));
show_debug_message(string_ext("Primitive count [0]: {0}", [gltf.get_primitive_count(0)]));
// box = gltf.generate_primitive(0, 0, vformat);
box = gltf.generate_model(vformat);

camera = new Camera();
material = new MaterialSpatial();
material.set_texture("albedo", sprite_get_texture(spr_missing_texture, 0));