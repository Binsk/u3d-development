/// @about
/// A 3D mesh is a collection of primitives that are paired with material indices.
///	Meshes do not contain material data themselves and rely on the rendering model
/// to provide the correct material data upon render based on the index.

function Mesh() : U3DObject() constructor {
	#region PROPERTIES
	primitive_array = [];	// Contains an array of structs of primitive / material values
	#endregion
	
	#region METHODS
	function get_primitive_count(){
		return array_length(primitive_array);
	}
	
	/// @desc	Adds a primitive into the system to be rendered and pairs it with
	///			a material index. Note that primitives can be added multiple times
	///			with different materials, if necessary.
	function add_primitive(primitive, material_index){
		array_push(primitive_array, {
			primitive, material_index
		});
	}
	
	/// @desc	Renders a single primitive.
	function render_primitive(index){
		if (index < 0 or index >= array_length(primitive_array))
			return;
			
		var primitive = primitive_array[index];
		vertex_submit(primitive.primitive.vbuffer, pr_trianglelist, -1);
	}
	
	/// @desc	Renders out each primitive, applying the specified materials 
	///			according to primitive IDs
	function render(material_data={}, render_stage=RENDER_STAGE.build_gbuffer){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (not is_undefined(material))
				material.apply(render_stage);
				
			render_primitive(i);
		}
	}
	
	#endregion
	
	#region INIT
	#endregion
}