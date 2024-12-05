/// @about
/// The PartitionNode is a special class used internally by the partitioning system.
/// It is a generic container that represents an axis-aligned area of space within
/// the partitioning structure.Nodes can generally hold one or more PartitionData
/// instances.

function PartitionNode(partition) constructor {
	#region PROPERTIES
	static INDEX_COUNTER = int64(0);
	index = INDEX_COUNTER++;
	
	self.partition = partition;	// Partition structure this belongs to
	parent = undefined;	// Parent node we are attached to
	self.aabb = aabb();
	child_array = [];	// Array of child PartitionNodes (usage depends on partition type)
	data_array = [];	// Array of partition data assigned to this node
	#endregion
	
	#region METHODS
	function get_data_count(){
		return array_length(data_array);
	}
	
	/// @desc	Adds another PartitionNode as the child of this node.
	/// @param	{PartitionNode}	node
	function add_child(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return false;
		}
			
		for (var i = array_length(child_array) - 1; i >= 0; --i){
			if (child_array[i].index == node.index)
				return false;
		}
		
		if (not is_undefined(node.parent))
			node.parent.remove_child(node);
			
		array_push(child_array, node);
		node.parent = self;
	}
	
	function remove_child(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return false;
		}
			
		for (var i = array_length(child_array) - 1; i >= 0; --i){
			if (child_array[i].index == node.index){
				node.parent = undefined;
				array_delete(child_array, i, 1);
				return true;
			}
		}
		
		return false;
	}
	
	function add_data(data){
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return false;
		}
		
		for (var i = array_length(data_array) - 1; i >= 0; --i){
			if (data_array[i].index == data.index)
				return false;
		}
		
		array_push(data_array, data);
		data.set_parent(self);
		
		return true;
	}
	
	function remove_data(data){
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return false;
		}
		
		for (var i = array_length(data_array) - 1; i >= 0; --i){
			if (data_array[i].index == data.index){
				array_delete(data_array, i, 1);
				data.parent = undefined;
				return true;
			}
		}
		
		return false;
	}
	
	/// @desc	Returns if this node has no child connections.
	function get_is_leaf(){
		return array_length(child_array) == 0;
	}
	
	/// @desc	Retruns if this node has no contained data.
	function get_is_empty(){
		return array_length(data_array) == 0;
	}
	
	/// @desc	Given PartitionData, checks if it intersects this node.
	function get_is_intersection(data){
		return aabb_intersects_aabb(data.aabb, self.aabb);
	}
	
	function calculate_surface_area(){
		return aabb_get_surface_area(self.aabb);
	}
	
	/// @desc	Calculates the necessary AABB to wrap around all child data.
	function calculate_child_data_aabb(){
		if (array_length(data_array) == 0)
			return aabb();
			
		var min_vec = vec(infinity, infinity, infinity);
		var max_vec = vec(-infinity, -infinity, -infinity);
		for (var i = array_length(data_array) - 1; i >= 0; --i){
			var data = data_array[i].aabb;
			min_vec = vec_min(min_vec, vec_sub_vec(data.position, data.extends));
			max_vec = vec_max(max_vec, vec_add_vec(data.position, data.extends));
		}
		var origin = vec_lerp(min_vec, max_vec, 0.5);
		var extends = vec_mul_scalar(vec_sub_vec(max_vec, min_vec), 0.5);

		return aabb(origin, extends);
	}
	
	function calculate_child_data_surface_area(){
		return aabb_get_surface_area(calculate_child_data_aabb());
	}
	
	/// @desc	Calculates the necessary AABB to wrap around all child nodes.
	function calculate_child_node_aabb(){
		if (array_length(child_array) == 0)
			return aabb();
			
		var naabb = undefined;
		for (var i = array_length(child_array) - 1; i >= 0; --i){
			var data = child_array[i];
			if (is_undefined(naabb))
				naabb = data.aabb;
			else
				naabb = aabb_add_aabb(naabb, data.aabb);
		}
		
		return naabb;
	}
	
	function calculate_child_node_surface_area(){
		return aabb_get_surface_area(calculate_child_node_aabb());
	}
	
	function render_debug(){
		var r_color = [0, get_is_leaf(), 1];
		var render_extends = self.aabb.extends;
		if (vec_is_zero(render_extends))
			return;
			
		var vformat = VertexFormat.get_format_instance([VERTEX_DATA.position]).get_format();
		var vbuffer = vertex_create_buffer();
		
		vertex_begin(vbuffer, vformat);
			// Top
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, -render_extends.z);
		
			// Bottom
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, -render_extends.z);
		
			// Edges:
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_end(vbuffer);
		
		uniform_set("u_vColor", shader_set_uniform_f, r_color);
		var matrix_model = matrix_get(matrix_world);
		
		matrix_set(matrix_world, matrix_build_translation(self.aabb.position));
		vertex_submit(vbuffer, pr_linelist, -1);
		matrix_set(matrix_world, matrix_model);
		
		vertex_delete_buffer(vbuffer);
	}
	#endregion
}