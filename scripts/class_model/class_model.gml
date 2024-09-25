/// @about
/// A Model is a collection of 1 or more Mesh instances as well as a number of
/// indexed Material instances.

function Model() : U3DObject() constructor {
	#region PROPERTIES
	material_data = {};	// An index -> material map of data
	mesh_array = [];	// Original array of meshes contained by the model
	#endregion
	
	#region METHODS
	/// @desc Add a new mesh into the model container, to render in-order.
	function add_mesh(mesh){
		if (not is_instanceof(mesh, Mesh)){
			Exception.throw_conditional("invalid type, expected [Mesh]!");
			return;
		}
		
		array_push(mesh_array, mesh);
	}
	
	/// @desc	Will assign a material to the specified index in the mesh.
	function set_material(material, material_index){
		if (not is_instanceof(material, Material)){
			Exception.throw_conditional("invalid type, expected [Material]!");
			return;
		}
			
		material_data[$ material_index] = material;
	}
	
	function render(render_stage=RENDER_STAGE.build_gbuffer){
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			mesh_array[i].render(material_data, render_stage);
	}
	#endregion
}