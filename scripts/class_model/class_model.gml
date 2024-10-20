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
		
		add_child_ref(mesh);
		array_push(mesh_array, mesh);
	}
	
	/// @desc	Will assign a material to the specified index in the mesh.
	function set_material(material, material_index){
		if (not is_instanceof(material, Material)){
			Exception.throw_conditional("invalid type, expected [Material]!");
			return;
		}
			
		add_child_ref(material);
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
	
	function render_shadows(){
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			mesh_array[i].render_shadows(material_data);
	}
	
	/// @desc		Will execute a buffer freeze on all attached meshes, loading them into
	///				vRAM. Much faster to render but constantly takes up vRAM.
	/// @warning	For dynamically generated resources, this will apply a freeze in ALL
	///				models using the resources!
	function freeze(){
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			mesh_array[i].freeze();
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		material_data = {};
		mesh_array = [];
	}
	#endregion
}