/// @about
/// A MultiModel is a way to render a single model in multiple places at once 
///	but in a more optimized fashion. This can be used to improve performance
/// if you have bunches or groups of the same model in one place that only
/// differ in orientation, translation, or scale. 
///
///	@note	This is not true multi-instance rendering, it simply aims to reduce
///			re-sending textures over-and-over. It is especially effective with
///			frozen buffers, otherwise you will still be sending buffer data
///			over-and-over.
function MultiModel() : Model() constructor {
	#region PROPERTIES
	node_array = [];	// Array of nodes that are used to contain model transforms
	#endregion
	
	#region METHODS
	function get_node_array(){
		return array_duplicate_shallow(node_array);
	}
	
	/// @desc	Adds a node to be used to define a render position.
	function add_node(node){
		if (not is_instanceof(node, Node)){
			Exception.throw_conditional("invalid type, expected [Node]!");
			return false;
		}
		
		for (var i = array_length(node_array) - 1; i >= 0; --i){
			if (U3DObject.are_equal(node, node_array[i]))
				return false;
		}
		
		array_push(node_array, node);
		node.signaler.add_signal("free", new Callable(self, self.remove_node, [node]));
		self.add_child_ref(node);
		return true;
	}
	
	/// @desc	Remose a node from the render order.
	function remove_node(node){
		if (not is_instanceof(node, Node)){
			Exception.throw_conditional("invalid type, expected [Node]!");
			return false;
		}
		
		for (var i = array_length(node_array) - 1; i >= 0; --i){
			if (U3DObject.are_equal(node, node_array[i])){
				array_delete(node_array, i, 1);
				node.signaler.remove_signal("free", new Callable(self, self.remove_node, [node]));
				self.remove_child_ref(node);
				return true;
			}
		}
		
		return false;
	}
	
	/// @desc	Grabs the data from the specified model and copies it over.
	function copy_from_model(model){
		if (not is_instanceof(model, Model)){
			Exception.throw_conditional("invalid type, expected [Model]!");
			return;
		}
		
		// Manually remove resources so references get cleaned up:
		var array = self.get_mesh_array();
		for (var i = array_length(array) - 1; i >= 0; --i)
			self.remove_mesh(array[i]);
			
		array = struct_get_names(material_data);
		for (var i = array_length(array) - 1; i >= 0; --i)
			self.set_material(undefined, array[i]);
		
		// Copy in other model's data:
		array = model.get_mesh_array();
		var loop = array_length(array);
		for (var i = 0; i < loop; ++i)
			self.add_mesh(array[i]);
		
		array = struct_get_names(model.material_data);
		for (var i = array_length(array) - 1; i >= 0; --i)
			self.set_material(model.material_data[$ array[i]], array[i]);
	}
	
	super.register("render");
	function render(data={}){
		data.node_array = node_array;
		super.execute("render", [data]);
	}
	
	super.register("render_shadows");
	function render_shadows(data={}){
		data.node_array = node_array;
		super.execute("render_shadows", [data]);
	}
	#endregion
}