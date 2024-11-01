/// @about
/// A 3D mesh is a collection of primitives that are paired with material indices.
///	Meshes do not contain material data themselves and rely on the rendering model
/// to provide the correct material data upon render based on the index.
///
/// @note	GLTF allows nodes to specify meshes so you can have multiples of
///			the same mesh in different locations. To prevent memory duplication, 
///			meshes will contain an optional local matrix built from these transforms
///			that is applied to each primitive rendered.
function Mesh() : U3DObject() constructor {
	#region PROPERTIES
	primitive_array = [];		// Contains an array of structs of primitive / material values
	matrix_model = undefined;	// If set, gets applied to each primitive.
	matrix_import = undefined;	// If 'apply transforms' is on when importing a model, the transform is stored here
	#endregion
	
	#region METHODS
	function get_primitive_count(){
		return array_length(primitive_array);
	}
	
	function get_triangle_count(){
		var count = 0;
		for (var i = array_length(primitive_array) - 1; i >= 0; --i)
			count += primitive_array[i].primitive.get_triangle_count();
		
		return count;
	}
	
	/// @desc	Adds a primitive into the system to be rendered and pairs it with
	///			a material index. Note that primitives can be added multiple times
	///			with different materials, if necessary.
	function add_primitive(primitive, material_index){
		array_push(primitive_array, {
			primitive, material_index, 
			has_bones : primitive.get_has_bones()
		});
		
		add_child_ref(primitive);
	}
	
	function apply_matrix(){
		if (is_undefined(matrix_model))
			return;
		
		matrix_set(matrix_world, matrix_multiply_post(matrix_get(matrix_world), matrix_model));
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
	function render(material_data={}, camera_id=undefined, render_stage=CAMERA_RENDER_STAGE.opaque, skeleton=U3D.RENDERING.ANIMATION.skeleton_missing){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (is_undefined(material))
				material = U3D.RENDERING.MATERIAL.missing;
				
			if (material.render_stage & render_stage <= 0) // Don't render, wrong stage
				return;
				
			material.apply(camera_id, render_stage==CAMERA_RENDER_STAGE.translucent);

/// @stub	Optimize it prevent re-sending data
			if (primitive_array[i].has_bones)
				uniform_set("u_mBone", shader_set_uniform_matrix_array, [skeleton]);
				
			render_primitive(i);
		}
	}
	
	function render_shadows(material_data={}, skeleton=U3D.RENDERING.ANIMATION.skeleton_missing){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (is_undefined(material))
				material = U3D.RENDERING.MATERIAL.missing;
				
			if (material.render_stage & CAMERA_RENDER_STAGE.opaque != CAMERA_RENDER_STAGE.opaque)
				continue;
				
			material.apply_shadow();

/// @stub	Optimize it prevent re-sending data
			if (primitive_array[i].has_bones)
				uniform_set("u_mBone", shader_set_uniform_matrix_array, [skeleton]);
			
			render_primitive(i);
		}
	}
	
	/// @desc		Will execute a buffer freeze on all attached primitives, loading them into
	///				vRAM. Much faster to render but constantly takes up vRAM.
	/// @warning	For dynamically generated resources, this will apply a freeze in ALL
	///				meshes using the resources!
	function freeze(){
		for (var i = array_length(primitive_array) - 1; i >= 0; --i)
			primitive_array[i].primitive.define_freeze();
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		
		primitive_array = [];
	}
	
	function duplicate(){
		var mesh = new Mesh();
		var al = array_length(primitive_array); 
		// Add primitives manually so their references are adjusted properly
		for (var i = 0; i < al; ++i){
			var primitive = primitive_array[i];
			mesh.add_primitive(primitive.primitive, primitive.material_index);
		}
		
		mesh.matrix_model = matrix_model;
		mesh.matrix_import = matrix_import;
		return mesh;
	}
	
	#endregion
	
	#region INIT
	#endregion
}