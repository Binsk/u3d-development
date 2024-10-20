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
		
		add_child_ref(primitive);
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
	function render(material_data={}, camera_id=undefined, render_stage=CAMERA_RENDER_STAGE.opaque){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (is_undefined(material))
				material = U3D.RENDERING.MATERIAL.missing;
				
			material.apply(camera_id, render_stage==CAMERA_RENDER_STAGE.translucent);
			
			if (material.render_stage & render_stage <= 0) // Don't render, wrong stage
				return;
				
			render_primitive(i);
		}
	}
	
	function render_shadows(material_data={}){
		for (var i = get_primitive_count() - 1; i >= 0; --i){
			var material_index = primitive_array[i].material_index;
			var material = material_data[$ material_index];
			if (is_undefined(material))
				material = U3D.RENDERING.MATERIAL.missing;
				
			material.apply_shadow();
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
	
	#endregion
	
	#region INIT
	#endregion
}