/// @about
/// A Model is a collection of Mesh and Material instances and is responsible
/// for submitting rendering info to the renderer.

function Model() : U3DObject() constructor {
	#region PROPERTIES
	material_data = {};	// An index -> material map of data
	mesh_array = [];	// Original array of meshes contained by the model
	#endregion
	
	#region METHODS
	/// @desc	Will assign a material to the specified index in the mesh.
	/// @param	{Material}	material	material to assign
	/// @param	{real}		index		slot index the material should be applied to
	function set_material(material, material_index){
		if (not is_instanceof(material, Material) and not is_undefined(material)){
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

	/// @desc	Returns the array of meshes to be rendered by this model.
	function get_mesh_array(){
		return array_duplicate_shallow(mesh_array);
	}

	/// @desc	Retruns an array of primitives to be rendered by this model.
	function get_primitive_array(){
		var array = [];
		for (var i = array_length(mesh_array) - 1 ; i >= 0; --i)
			array = array_concat(array, mesh_array[i].get_primitive_array());
		
		return array;
	}

	/// @desc	Returns an array of all the materials attached to the model.
	///	@note	Array indices do NOT correlate to material indices!
	function get_material_array(){
		return struct_get_values(material_data);
	}

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

	function remove_mesh(mesh){
		if (not is_instanceof(mesh, Mesh)){
			Exception.throw_conditional("invalid type, expected [Mesh]!");
			return;
		}
		
		for (var i = array_length(mesh_array) - 1; i >=0; --i){
			if (U3DObject.are_equal(mesh_array[i], mesh)){
				remove_child_ref(mesh);
				array_delete(mesh_array, i, 1);
			}
		}
	}

	/// @desc Renders the model out, applying materials as needed.
	/// @param	{struct}	data	arbitrary data calculated by the renderer
	function render(data={}){
		var matrix = matrix_get(matrix_world); // Meshs can modify, so reset after each mesh
		for (var i = array_length(mesh_array) - 1; i >= 0; --i){
			mesh_array[i].apply_matrix();
			mesh_array[i].render(material_data, data);
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
	
	/// @desc	Replaces any materials with a hash with a unique duplicate of
	///			the material; auto-hashed to the model to be freed when the
	///			model is. Useful for models that may need custom scalar properties.
	///			If a material IS NOT HASHED then it will not be duplicated in order
	///			to prevent any possible memory leaks.
	/// @note	This does NOT duplicate stored referenced data, such as textures,
	///			in order to save RAM/vRAM.
	function generate_unique_materials(){
		var keys = struct_get_names(material_data);
		for (var i = array_length(keys) - 1; i >= 0; --i){
			var material = material_data[$ keys[i]];
			if (is_undefined(material.hash))
				continue;
				
			var nmaterial = material.duplicate();
			nmaterial.generate_unique_hash();
			set_material(nmaterial, real(keys[i]));
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