/// @about
/// A Model is a collection of Mesh and Material instances and is responsible
/// for submitting rendering info to the renderer.

function Model() : U3DObject() constructor {
	#region PROPERTIES
	material_data = {};	// An index -> material map of data
	mesh_array = [];	// Original array of meshes contained by the model
	#endregion
	
	#region METHODS
	/// @desc Add a new mesh into the model container, to render in-order.
	/// @param	{Mesh}	mesh
	function add_mesh(mesh){
		if (not is_instanceof(mesh, Mesh)){
			Exception.throw_conditional("invalid type, expected [Mesh]!");
			return;
		}
		
		add_child_ref(mesh);
		array_push(mesh_array, mesh);
	}
	
	/// @desc	Will assign a material to the specified index in the mesh.
	/// @param	{Material}	material	material to assign
	/// @param	{real}		index		slot index the material should be applied to
	function set_material(material, material_index){
		if (not is_instanceof(material, Material)){
			Exception.throw_conditional("invalid type, expected [Material]!");
			return;
		}
			
		replace_child_ref(material, material_data[$ material_index]);
		material_data[$ material_index] = material;
	}
	
	/// @desc	Given a material index for the model, returns the material
	///			stored in that slot. If the material doesn't exist then the
	///			'missing' material is returned.
	/// @param	{real}	index
	function get_material(index){
		return material_data[$ index] ?? U3D.RENDERING.MATERIAL.missing;
	}
	
	/// @desc	Returns the number of primitives that this model will render.
	function get_primitive_count(){
		var count = 0;
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			count += mesh_array[i].get_primitive_count();
		
		return count;
	}
	
	/// @desc	Returns the number of meshes referenced by this model.
	function get_mesh_count(){
		return array_length(mesh_array);
	}
	
	/// @desc	Returns the number of materials referenced by this model.
	function get_material_count(){
		return struct_names_count(material_data);
	}
	
	/// @desc	Returns the number of triangles that will be rendered by 
	///			this model (not including the shadow pass).
	function get_triangle_count(){
		var count = 0;
		for (var i = array_length(mesh_array) - 1; i >= 0; --i)
			count += mesh_array[i].get_triangle_count();
		
		return count;
	}

	/// @desc Renders the model out, applying materials as needed.
	/// @param	{Camera}	camera_id		id of the camera that is currently rendering
	/// @param	{CAMERA_RENDER_STAGE}	render_stage	currently rendering stage
	/// @param	{struct}	data	arbitrary data calculated by the renderer
	function render(camera_id=undefined, render_stage=CAMERA_RENDER_STAGE.opaque, data={}){
		var matrix = matrix_get(matrix_world); // Meshs can modify, so reset after each mesh
		for (var i = array_length(mesh_array) - 1; i >= 0; --i){
			mesh_array[i].apply_matrix();
			mesh_array[i].render(material_data, camera_id, render_stage, data);
			matrix_set(matrix_world, matrix);
		}
	}
	
	/// @desc	Renders the model out specifically for the shadow pass.
	/// @param	{struct}	data	arbitrary data calculated by the renderer
	function render_shadows(data={}){
		var matrix = matrix_get(matrix_world); // Meshs can modify, so reset after each mesh
		for (var i = array_length(mesh_array) - 1; i >= 0; --i){
			mesh_array[i].apply_matrix();
			mesh_array[i].render_shadows(material_data, data);
			matrix_set(matrix_world, matrix);
		}
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