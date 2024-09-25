vformat = new VertexFormat([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture]);

var gltf = new GLTFBuilder("block.glb");
show_debug_message(string_ext("Mesh count: {0}", [gltf.get_mesh_count()]));
show_debug_message(string_ext("Primitive count [0]: {0}", [gltf.get_primitive_count(0)]));
box = gltf.generate_model(vformat);
material_array = gltf.generate_material_array();
for (var i = 0; i < array_length(material_array); ++i)
	box.set_material(material_array[i], i);

camera = new Camera();
// material = new MaterialSpatial();
// material.set_texture("albedo", sprite_get_texture(spr_missing_texture, 0));