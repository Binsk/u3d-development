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
		
		mesh.increment_reference();
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
	
	/// @desc	Given a material index for the model, returns the material
	///			stored in that slot. If the material doesn't exist then the
	///			'missing' material is returned.
	function get_material(index){
		return material_data[$ index] ?? U3D.RENDERING.MATERIAL.missing;
	}

	function render(camera_id=undefined, render_stage=CAMERA_RENDER_STAGE.opaque){
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			mesh_array[i].render(material_data, camera_id, render_stage);
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		
		// Clean up any dynamic materials 
		var material_keys = struct_get_names(material_data);
		for (var i = array_length(material_keys) - 1; i >= 0; --i)
			material_data[$ material_keys[i]].decrement_reference();
		
		material_data = {};
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			mesh_array[i].decrement_reference();

		mesh_array = [];
	}
	#endregion
}