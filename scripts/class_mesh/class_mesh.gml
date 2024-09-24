/// @about
/// A 3D mesh is a collection of primitives that are paired with material indices.
///	Meshes do not contain material data themselves and rely on the rendering model
/// to provide the correct material data upon render based on the index.

function Mesh() : U3DObject() constructor {
	#region PROPERTIES
	primitive_array = [];	// Contains an array of structs of primitive / material values
	#endregion
	
	#region METHODS
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