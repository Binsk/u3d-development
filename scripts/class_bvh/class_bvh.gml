/// @about
/// This class defines a Bounding Volume Hierarchy in the form of a BSP.
/// This partitioning system excels at partitioning space for 3D bodies with
/// volume. BVH structures are generally more expensive to set up than to scan.
/// This BVH will self-balance as items are added and removed.

/// @param	{real}	depth_max		the maximum depth the tree can build
/// @param	{real}	instance_max	the maximum instances stored per leaf; gets overridden if the tree runs out of depth
function BVH(depth_max=8, instance_max=2) : Partition() constructor {
	#region PROPERTIES
	static BVH_SPLIT_THRESHOLD = 0.3;	// How much difference there must be before splitting a node
	
	self.node_root = new PartitionNode(self);
	self.depth_max = depth_max;	
	self.instance_max = instance_max;
	#endregion
	
	#region STATIC METHODS
	/// @desc	Returns the surface area of the specific node; used when determining
	///			how to split.
	/// @param	{PartitionNode}	node		the node to calculate the surface area of
	/// @param	{PartitionData}	data		if specified, includes bounds in surface area calculation
	static calculate_node_surface_area = function(node, data=undefined){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return 0;
		}
		
		var _aabb = aabb_duplicate(node.aabb);
		
		if (not is_undefined(data)){
			if (not is_instanceof(data, PartitionData)){
				Exception.throw_conditional("invalid type, expected [PartitionData]!");
				return 0;
			}
			_aabb = aabb_add_aabb(_aabb, data.aabb);
		}
		
		return aabb_get_surface_area(_aabb);
	}
	
	static set_node_depth = function(node, depth){
		node.depth = depth;
		for (var i = array_length(node.child_array) - 1; i >= 0; --i)
			BVH.set_node_depth(node.child_array[i], depth - 1);
	}
	
	/// @desc	Pushes data down the tree and updates. Does NOT recalculate parents;
	///			that is assumed to be done after this.
	static push_data = function(node, data){
		var node_merged = new PartitionNode(node.partition);
		node_merged.child_array = node.child_array;	// Shift child nodes over
		node_merged.parent = node;
		node.child_array[0].parent = node_merged;
		node.child_array[1].parent = node_merged;
		
		var node_new = new PartitionNode(node.partition);
		node_new.parent = node;
		node_new.add_data(data);
		
		// Update new nodes bounds:
		node_merged.aabb = (node_merged.get_is_leaf() ? node_merged.calculate_child_data_aabb() : node_merged.calculate_child_node_aabb());
		node_merged.surface_area = node_merged.calculate_surface_area();
		node_new.aabb = (node_new.get_is_leaf() ? node_new.calculate_child_data_aabb() : node_new.calculate_child_node_aabb());
		node_new.surface_area = node_new.calculate_surface_area();
		
		node.child_array = [	// Assign new nodes to old node as children
			node_merged, 
			node_new
		];
		
		node.aabb = node.calculate_child_node_aabb();
		node.surface_area = node.calculate_surface_area();
		BVH.set_node_depth(node, node.depth);
	}
	
	static split_node = function(node){
		// Returns as struct of potential surfaces areas when splitting based on a list
		function calculate_surface_areas(priority){
			var left_array = array_create(floor(ds_priority_size(priority) * 0.5));
			var right_array = array_create(ds_priority_size(priority) - array_length(left_array));
			var index = 0;
			
			// Split instances into two ~equal groups
			repeat (array_length(left_array))
				left_array[index++] = ds_priority_delete_min(priority);
			
			index = 0;
			repeat (array_length(right_array))
				right_array[index++] = ds_priority_delete_min(priority);
			
			// Calculate surface areas for each
			var surface_area = 0;
			var aabb_left = undefined;
			var aabb_right = undefined;
			for (var i = array_length(left_array) - 1; i >= 0; --i){
				var data = left_array[i];
				if (is_undefined(aabb_left))
					aabb_left = data.aabb;
				else
					aabb_left = aabb_add_aabb(aabb_left, data.aabb);
			}
			
			for (var i = array_length(right_array) - 1; i >= 0; --i){
				var data = right_array[i];
				if (is_undefined(aabb_right))
					aabb_right = data.aabb;
				else
					aabb_right = aabb_add_aabb(aabb_right, data.aabb);
			}
			
			surface_area = aabb_get_surface_area(aabb_left) * array_length(left_array) + aabb_get_surface_area(aabb_right) * array_length(right_array);
			
			return {
				left_array : left_array,
				right_array : right_array,
				surface_area : surface_area
			}
		}
		
		var priority_x = ds_priority_create();
		var priority_y = ds_priority_create();
		var priority_z = ds_priority_create();
		
		// Sort instances by axis:
		for (var i = array_length(node.data_array) - 1; i >= 0; --i){
			var data = node.data_array[i];
			ds_priority_add(priority_x, data, data.aabb.position.x);
			ds_priority_add(priority_y, data, data.aabb.position.y);
			ds_priority_add(priority_z, data, data.aabb.position.z);
		}
		
		// Calculate potential surface areas:
		var sa_x = calculate_surface_areas(priority_x);
		var sa_y = calculate_surface_areas(priority_y);
		var sa_z = calculate_surface_areas(priority_z);
		
		// Pick the split w/ the smallest surface area:
		var left_array, right_array;
		if (sa_x.surface_area <= sa_y.surface_area){
			if (sa_x.surface_area <= sa_z.surface_area){
				left_array = sa_x.left_array;
				right_array = sa_x.right_array;
			}
			else {
				left_array = sa_z.left_array;
				right_array = sa_z.right_array;
			}
		}
		else if (sa_y.surface_area < sa_z.surface_area) {
			left_array = sa_y.left_array;
			right_array = sa_y.right_array;
		}
		else {
			left_array = sa_z.left_array;
			right_array = sa_z.right_array;
		}
		
		ds_priority_destroy(priority_x);
		ds_priority_destroy(priority_y);
		ds_priority_destroy(priority_z);
		
		// Generate new nodes to add the groups to:
		var node_left = new PartitionNode(node.partition);
		node_left.data_array = left_array;
		node_left.parent = node;
		node_left.aabb = node_left.calculate_child_data_aabb();
		node_left.surface_area = node_left.calculate_surface_area();
		node_left.depth = node.depth - 1;
		for (var i = array_length(left_array) - 1; i >= 0; --i)
			left_array[i].set_parent(node_left);
		
		var node_right = new PartitionNode(node.partition);
		node_right.data_array = right_array;
		node_right.parent = node;
		node_right.aabb = node_right.calculate_child_data_aabb();
		node_right.surface_area = node_right.calculate_surface_area();
		node_right.depth = node.depth - 1;
		for (var i = array_length(right_array) - 1; i >= 0; --i)
			right_array[i].set_parent(node_right);
		
		// Add the new nodes to the original and update:
		node.child_array = [
			node_left,
			node_right
		];
		
		node.data_array = [];
		node.aabb = node.calculate_child_node_aabb();
		node.surface_area = node.calculate_surface_area();
	}
	
	static delete_leaf = function(node) {
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return;
		}
		
		if (not node.get_is_leaf()){
			Exception.throw_conditional("failed to delete node, node is not [leaf]!");
			return;
		}
		
		var node_parent = node.parent;
		
		if (is_undefined(node_parent)) // Root node; don't delete
			return;
		
		if (node_parent.get_is_leaf())
			throw new Exception("failed to delete node, parent is [leaf]!"); // Should NOT be happening; else there is something wrong w/ node relations
		
		// Shift data up to the parent:
		node_parent.remove_child(node);
		
		var node_sibling = node_parent.child_array[0];	// Remaining child node
		node_parent.remove_child(node_sibling);
		
		node_parent.child_array = node_sibling.child_array;
/// @fixme	The parent SHOULD NOT HAVE data! Only leaves should, something is wrong here!
		node_parent.data_array = array_concat(node_sibling.data_array, node_parent.data_array);
		
		// Update relations:
		for (var i = array_length(node_parent.data_array) - 1; i >= 0; --i)
			node_parent.data_array[i].set_parent(node_parent);
		
		for (var i = array_length(node_parent.child_array) - 1; i >= 0; --i)
			node_parent.child_array[i].parent = node_parent;
		
		BVH.set_node_depth(node_parent, node_parent.depth);
		
		delete node;
		delete node_sibling;
		
		node_parent.aabb = (node_parent.get_is_leaf() ? node_parent.calculate_child_data_aabb() : node_parent.calculate_child_node_aabb());
		node_parent.surface_area = node_parent.calculate_surface_area();
	}
	
	static get_root_node = function(node){
		var node_parent = node;
		while (not is_undefined(node_parent.parent))
			node_parent = node_parent.parent;
			
		return node_parent;
	}
	#endregion
	
	#region METHODS
	/// @desc	Scans the tree and returns an array of all the node structures:
	function get_node_array(){
		var node_queue = ds_queue_create();
		var process_queue = ds_queue_create();
		ds_queue_enqueue(process_queue, node_root);
		
		while (not ds_queue_empty(process_queue)){
			var node = ds_queue_dequeue(process_queue);
			ds_queue_enqueue(node_queue, node);
			
			for (var i = array_length(node.child_array) - 1; i >= 0; --i)
				ds_queue_enqueue(process_queue, node.child_array[i]);
		}
		
		var array = array_create(ds_queue_size(node_queue));
		var index = ds_queue_size(node_queue) - 1;
		while (not ds_queue_empty(node_queue))
			array[index--] = ds_queue_dequeue(node_queue);
		
		ds_queue_destroy(process_queue);
		ds_queue_destroy(node_queue);
		return array;
	}
	
	function scan_collisions(data){
		var node_array = get_node_array();
		var array = [];
		for (var i = array_length(node_array) - 1; i >= 0; --i){
			var node = node_array[i];
			array_push(array, node.data_array);
		}
		
		return array_flatten(array);
	}
	
	/// @desc	Attempts to add a piece of data to the tree; scanning nodes as
	///			appropriate and spawning / adjusting as necessary.
	super.register("add_data")
	function add_data(data){
		if (not super.execute("add_data", [data]))
			return false;
			
		var update_stack = ds_stack_create(); // Used to update AABBs and surface area of parent nodes
		var depth_current = depth_max;
		var node = node_root;
		while (not node.get_is_leaf() and node.depth > 0){
			// Calculate surface areas + adjusted surface areas:
			var sa_left = (node.child_array[0][$ "surface_area"] ?? aabb_get_surface_area(node.child_array[0].aabb));
			var sa_right = (node.child_array[1][$ "surface_area"] ?? aabb_get_surface_area(node.child_array[1].aabb));
			var sa_left_adj = sa_right + calculate_node_surface_area(node.child_array[0], data);
			var sa_right_adj = sa_left + calculate_node_surface_area(node.child_array[1], data);
			var sa_combined = aabb_get_surface_area(aabb_add_aabb(node.child_array[0].aabb, node.child_array[1].aabb)) + aabb_get_surface_area(data.aabb);
			
			if (sa_combined < min(sa_left_adj, sa_right_adj) * BVH.BVH_SPLIT_THRESHOLD){ // Push down node
				ds_stack_push(update_stack, node);
				BVH.push_data(node, data);
				while (not ds_stack_empty(update_stack)){
					var pnode = ds_stack_pop(update_stack);
					pnode.aabb = pnode.calculate_child_node_aabb();
					pnode.surface_area = pnode.calculate_surface_area();
				}
				ds_stack_destroy(update_stack);
				return true;
				
			}
			else { // Process down the children
				ds_stack_push(update_stack, node);
				if (sa_left_adj < sa_right_adj) // Left wins
					node = node.child_array[0];
				else // Right wins
					node = node.child_array[1];
			}
		}
		
		// Add the data to the final node:
		node.add_data(data);
		
		if (node.get_data_count() > self.instance_max and node.depth > 0){
			ds_stack_push(update_stack, node);
			BVH.split_node(node);
		}
		else {
			node.aabb = node.calculate_child_data_aabb();
			node.surface_area = node.calculate_surface_area();
		}
		
		while (not ds_stack_empty(update_stack)){
			var pnode = ds_stack_pop(update_stack);
			pnode.aabb = pnode.calculate_child_node_aabb();
			pnode.surface_area = pnode.calculate_surface_area();
		}
		ds_stack_destroy(update_stack);
			
		return true;
	}
	
	super.register("remove_data");
	function remove_data(data){
		if (not super.execute("remove_data", [data]))
			return false;

		var node = data.parent;
		if (is_undefined(node))
			return false;

		node.remove_data(data);
		var node_parent = node.parent;
		if (node.get_is_empty()){
			BVH.delete_leaf(node);
			if (not is_undefined(node_parent))
				node_parent = node_parent.parent;
			
		}
		else{
			node.aabb = node.calculate_child_data_aabb();
			node.surface_area = node.calculate_surface_area();
		}
		
		while (not is_undefined(node_parent)){
			node_parent.aabb = node_parent.calculate_child_node_aabb();
			node_parent.surface_area = node.calculate_surface_area();
			node_parent = node_parent.parent;
		}
		
		return true;
	}
	
	function render_debug(){
		if (keyboard_check_pressed(ord("1")))
			show_message(node_root.child_array);
		
		var node_array = get_node_array();
		
		for (var i = array_length(node_array) - 1; i >= 0; --i)
			node_array[i].render_debug();
	}
	#endregion
	
	#region INIT
	self.node_root.depth = depth_max;
	self.node_root.partition = self;
	#endregion
}