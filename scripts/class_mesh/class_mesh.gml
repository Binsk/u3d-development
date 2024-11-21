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
	matrix_model = undefined;	// If set, gets applied to each primitive; used when there are mesh duplicates in the model
	matrix_import = undefined;	// If 'apply transforms' is on when importing a model, the transform is stored here
	#endregion
	
	#region METHODS
	
	/// @desc	Given a U3DObject index, sets a limited set of triangle to render for the
	///			related primitive. If that primitive isn't set in the mesh then nothing will be
	///			changed. Returns the number of primitives affected.
	/// @param	{any}	u3d_index_or_instance		the U3DObject instance of the primitive or the primitive instance itself
	/// @param	{real}	triangle_start				triangle index to start rendering at
	/// @param	{real}	triangle_count				number of triangles to render
	function set_primitive_triangle_limit(u3d_index_or_instance, triangle_start=0, triangle_count=infinity){
		var u3d_index = -1;
		if (U3DObject.get_is_valid_object(u3d_index_or_instance))
			u3d_index = u3d_index_or_instance.get_index();
		else
			u3d_index = u3d_index_or_instance;
			
		var count = 0;
		for (var i = array_length(primitive_array) - 1; i >= 0; --i){
			var data = primitive_array[i];
			if (data.primitive.get_index() != u3d_index)
				continue;
			
			data.triangle_start = (triangle_start == 0 ? undefined : triangle_start);
			data.triangle_count = (triangle_count >= infinity ? undefined : triangle_count);
			++count;
		}
		
		return count;
	}
	
	/// @desc Returns the number of primitives contained in the mesh.
	/// @returns {real}
	function get_primitive_count(){
		return array_length(primitive_array);
	}
	
	/// @desc Returns the total number of triangles in the mesh across all primitives.
	/// @returns {real}
	function get_triangle_count(){
		var count = 0;
		for (var i = array_length(primitive_array) - 1; i >= 0; --i)
			count += primitive_array[i].primitive.get_triangle_count();
		
		return count;
	}
	
	/// @desc	Retruns an array of primitives being rendered by this mesh.
	function get_primitive_array(){
		var array = array_create(array_length(primitive_array));
		for (var i = array_length(array) - 1; i >= 0; --i)
			array[i] = primitive_array[i].primitive;
		
		return array;
	}
	
	/// @desc	Adds a primitive into the system to be rendered and pairs it with
	///			a material index. Note that primitives can be added multiple times
	///			with different materials, if necessary.
	/// @param	{Primitive}	primitive
	/// @param	{real}		material_index
	function add_primitive(primitive, material_index){
		array_push(primitive_array, {
			primitive, material_index, 
			has_bones : primitive.get_has_bones()
		});
		
		add_child_ref(primitive);
	}
	
	/// @desc	Applies the custom model matrix to the current world matrix.
	function apply_matrix(){
		if (is_undefined(matrix_model))
			return;
		
		matrix_set(matrix_world, matrix_multiply_post(matrix_get(matrix_world), matrix_model));
	}
	
	/// @desc	Renders a single primitive.
	/// @param	{real}	index		index of the primitive to render
	function render_primitive(index){
		if (index < 0 or index >= array_length(primitive_array))
			return;
			
		var primitive = primitive_array[index];
		var triangle_start = primitive[$ "triangle_start"] ?? 0;
		var triangle_count = primitive[$ "triangle_count"] ?? infinity;
		primitive.primitive.submit(Camera.ACTIVE_INSTANCE.debug_flags & CAMERA_DEBUG_FLAG.render_wireframe, triangle_start, triangle_count);
	}
	
	/// @desc	Renders out each primitive, applying the specified materials
	///			according to primitive IDs
	/// @param	{struct}	material_data	a struct containing material index -> Material() pairs
	/// @param	{Camera}	camera_id		id of the camera that is currently rendering
	/// @param	{CAMERA_RENDER_STAGE} render_stage	the currently executing render stage
	/// @param	{struct}	data			arbitrary data calculated by the renderer; things like skeletal animation
	function render(material_data={}, camera_id=undefined, render_stage=CAMERA_RENDER_STAGE.opaque, data={}){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (is_undefined(material))
				material = material_index < 0 ? U3D.RENDERING.MATERIAL.blank : U3D.RENDERING.MATERIAL.missing;
				
			if (material.render_stage & render_stage <= 0) // Don't render, wrong stage
				return;
				
			material.apply(camera_id, render_stage==CAMERA_RENDER_STAGE.translucent);

/// @stub	Optimize it prevent re-sending data
			if (primitive_array[i].has_bones){
				uniform_set("u_mBone", shader_set_uniform_matrix_array, [data.skeleton]);
				uniform_set("u_iBoneNoScale", shader_set_uniform_i, [data.skeleton_bone_count > U3D_MAXIMUM_BONES]);
			}
				
			render_primitive(i);
		}
	}
	
	/// @desc	Renders out each primitive specifically for the shadow pass.
	/// @param	{struct}	material_data	a struct containing material index -> Material() pairs
	/// @param	{struct}	data			arbitrary data calculated by the renderer; things like skeletal animation-
	function render_shadows(material_data={}, data={}){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (is_undefined(material))
				material = U3D.RENDERING.MATERIAL.missing;
				
			if (material.render_stage & CAMERA_RENDER_STAGE.opaque != CAMERA_RENDER_STAGE.opaque)
				continue;
			
			if (not material.get_casts_shadows())
				continue;
				
			material.apply_shadow();

/// @stub	Optimize it prevent re-sending data
			if (primitive_array[i].has_bones){
				uniform_set("u_mBone", shader_set_uniform_matrix_array, [data.skeleton]);
				uniform_set("u_iBoneNoScale", shader_set_uniform_i, [data.skeleton_bone_count > U3D_MAXIMUM_BONES]);
			}
			
			render_primitive(i);
		}
	}
	
	/// @desc		Will execute a buffer freeze on all attached primitives, loading them into
	///				vRAM. Much faster to render but constantly takes up vRAM.
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


