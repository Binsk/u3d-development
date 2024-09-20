/// ABOUT
/// A 3D mesh that can be displayed in the 3D game world. Each mesh can be constructed
///	out of numerous primitives and materials and will be rendered out together.

function Mesh() : U3DObject() constructor {
	#region PROPERTIES
	material_data = {};	// Contains index -> material pairs
	primitive_array = [];	// Contains an array of structs of primitive / material values
	#endregion
	
	#region METHODS
	/// @desc	Will assign a material to the specified index in the mesh.
	function set_material(material, material_index){
		if (not is_instanceof(material, Material))
			throw new Exception("invalid type, expected [Material]!");
			
		material_data[$ material_index] = material;
	}
	
	/// @desc	Adds a primitive into the system to be rendered and pairs it with
	///			a material index. Note that primitives can be added multiple times
	///			with different materials, if necessary.
	function add_primitive(primitive, material_index){
		array_push(primitive_array, {
			primitive, material_index
		});
	}
	
	/// @desc	Renders a single primitive with the specified texture. This does not
	///			account for materials or any uniform data and simply submits the vertex data.
	///			This function can be used for various pass types, such as shading, lighting, 
	///			and so-forth.
	function render_primitive(index, texture){
		var primitive = primitive_array[index];
		vertex_submit(primitive.primitive.vbuffer, pr_trianglelist, texture);
	}
	#endregion
	
	#region INIT
	#endregion
}