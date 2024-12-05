/// @about
/// This class defines a Bounding Volume Hierarchy in the form of a BSP.
/// This partitioning system excels at partitioning space for 3D bodies with
/// volume. BVH structures are generally more expensive to set up than to scan.
/// This BVH will self-balance as items are added and removed.

/// @param	{real}	depth_max		the maximum depth the tree can build
/// @param	{real}	instance_max	the maximum instances stored per leaf; gets overridden if the tree runs out of depth
function BVH(depth_max=8, instance_max=1) : Partition() constructor {
	#region PROPERTIES
	static BVH_SPLIT_THRESHOLD = 0.3;	// How much difference there must be before splitting a node
	
	self.node_root = new PartitionNode(self);
	self.node_infinite = new PartitionNode(self);	// Special node for containing 'infinite' shapes (currently a work-around)
	self.depth_max = depth_max;	
	self.instance_max = instance_max;
	#endregion
	
	#region STATIC METHODS
	static set_node_depth = function(node, depth){
		node.depth = depth;
		for (var i = array_length(node.child_array) - 1; i >= 0; --i)
			BVH.set_node_depth(node.child_array[i], depth - 1);
	}
	
	static get_root_node = function(node){
		var node_parent = node;
		while (not is_undefined(node_parent.parent))
			node_parent = node_parent.parent;
			
		return node_parent;
	}
	
	/// @desc	Returns the 'left' node, or undefined, stored in the specified node.
	static get_node_left = function(node){
		var array = (node[$ "child_array"] ?? []);
		if (array_length(array) < 1)
			return undefined;
		
		return array[0];
	}
	
	/// @desc	Returns the 'right' node, or undefined, stored in the specified node.
	static get_node_right = function(node){
		var array = (node[$ "child_array"] ?? []);
		if (array_length(array) < 2)
			return undefined;
		
		return array[1];
	}
	
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
	
	/// @desc	Given a node, returns the maximum branch depth and returns the result.
	static calculate_node_branch_depth = function(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return 0;
		}
		
		if (node.get_is_leaf())
			return node.partition.depth_max - node.depth;
		
		var value = -infinity;
		for (var i = array_length(node.child_array) - 1; i >= 0; --i)
			value = max(value, BVH.calculate_node_branch_depth(node.child_array[i]));
			
		return value;
	}
	
	/// @desc	Attempts to balance the tree starting at the specified node. Returns the
	///			number of nodes balanced.
	static balance_node = function(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return;
		}
		
		if (node.get_is_leaf())
			return 0;
		
		var result = 0;
		result += BVH.balance_node(node.child_array[0]);
		result += BVH.balance_node(node.child_array[1]);
			
		var factor = BVH.calculate_node_branch_depth(node.child_array[0]) - BVH.calculate_node_branch_depth(node.child_array[1]);
		if (clamp(factor, -1, 1) == factor) // Pretty balanced, we're good to end
			return result;
		
		if (factor < 0)
			result += BVH.rotate_node_right(node);
		else
			result += BVH.rotate_node_left(node);
			
		if (node.get_data_count() > node.partition.instance_max and node.depth > 0){
			BVH.split_node(node);
			BVH.update_branch(node);
			result += BVH.balance_node(node.child_array[0]);
			result += BVH.balance_node(node.child_array[1]);
		}
			
		return result;
	}
	
	static rotate_node_right = function(node){ // From left to right, right to up, up to left
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return 0;
		}

		if (node.get_is_leaf())
			return 0;

		var node_left_a = BVH.get_node_left(node);
		var node_right_a = BVH.get_node_right(node);
		var node_left_b = BVH.get_node_left(node_right_a);
		var node_right_b = BVH.get_node_right(node_right_a);
		
		if (is_undefined(node_left_b) or is_undefined(node_right_b))
			return 0;
		
		if (not is_undefined(node.parent)){
			if (BVH.get_node_left(node.parent).index == node.index)
				node.parent.child_array[0] = node_right_a;
			else
				node.parent.child_array[1] = node_right_a;
			
			node_right_a.parent = node.parent;
		}
		else {
			node.partition.node_root = node_right_a;
			node_right_a.parent = undefined;
		}
		
		node_right_a.child_array[0] = node;
		node.parent = node_right_a;
		node.child_array[1] = node_left_b;
		node_left_b.parent = node;
		
		node_right_a.depth++;
		node_right_b.depth++;
		node_left_a.depth--;
		node.depth--;
		
		BVH.update_node(node_right_a);
		BVH.update_node(node_right_b);
		BVH.update_node(node);
		BVH.update_node(node_left_a);
		BVH.update_branch(node_left_b);
		return 1;
	}
	
	static rotate_node_left = function(node){ // From right to left, left to up, up to right
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return 0;
		}
		
		if (node.get_is_leaf())
			return 0;

		var node_left_a = BVH.get_node_left(node);
		var node_right_a = BVH.get_node_right(node);
		var node_left_b = BVH.get_node_left(node_left_a);
		var node_right_b = BVH.get_node_right(node_left_a);
		
		if (is_undefined(node_left_b) or is_undefined(node_right_b))
			return 0;
		
		if (not is_undefined(node.parent)){
			if (BVH.get_node_left(node.parent).index == node.index)
				node.parent.child_array[0] = node_left_a;
			else
				node.parent.child_array[1] = node_left_a;
			
			node_left_a.parent = node.parent;
		}
		else {
			node.partition.node_root = node_left_a;
			node_left_a.parent = undefined;
		}
		
		node_left_a.child_array[1] = node;
		node.parent = node_left_a;
		node.child_array[0] = node_right_b;
		node_right_b.parent = node;
		
		node_left_a.depth++;
		node_left_b.depth++;
		node_right_a.depth--;
		node.depth--;
		
		BVH.update_node(node_left_a);
		BVH.update_node(node_left_b);
		BVH.update_node(node);
		BVH.update_node(node_right_a);
		BVH.update_branch(node_right_b);
		return 1;
	}
	
	/// @desc	Pushes data down the tree and updates. Does NOT recalculate parents;
	///			that is assumed to be done after this.
	static push_data = function(node, data){
		var node_merged = new PartitionNode(node.partition);
		node_merged.child_array = node.child_array;	// Shift child nodes over
		node_merged.parent = node;
		node_merged.depth = node.depth - 1;
		BVH.update_node(node_merged);
		
		var node_new = new PartitionNode(node.partition);
		node_new.parent = node;
		node_new.add_data(data);
		node_new.depth = node.depth - 1;
		BVH.update_node(node_new);
		
		node.child_array = [	// Assign new nodes to old node as children
			node_merged, 
			node_new
		];
		
		BVH.update_node(node);
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
		node_left.depth = node.depth - 1;
		BVH.update_node(node_left);
		for (var i = array_length(left_array) - 1; i >= 0; --i)
			left_array[i].set_parent(node_left);
		
		var node_right = new PartitionNode(node.partition);
		node_right.data_array = right_array;
		node_right.parent = node;
		node_right.depth = node.depth - 1;
		BVH.update_node(node_right);
		for (var i = array_length(right_array) - 1; i >= 0; --i)
			right_array[i].set_parent(node_right);
		
		// Add the new nodes to the original and update:
		node.child_array = [
			node_left,
			node_right
		];
		
		node.data_array = [];
		BVH.update_node(node);
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
		
		node_parent.child_array = node_sibling.child_array;
		node_parent.data_array = node_sibling.data_array;

		delete node;
		delete node_sibling;
		
		BVH.update_node(node_parent);
	}
	
	/// @desc	Updates a node's properties, including AABB and so-forth. Does not
	///			recursively update parents or children.
	static update_node = function(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return;
		}
		
		node.aabb = (node.get_is_leaf() ? node.calculate_child_data_aabb() : node.calculate_child_node_aabb());
		node.surface_area = node.calculate_surface_area();
		BVH.set_node_depth(node, node.depth);
		for (var i = array_length(node.data_array) - 1; i >= 0; --i)
			node.data_array[i].set_parent(node);
		
		for (var i = array_length(node.child_array) - 1; i >= 0; --i)
			node.child_array[i].parent = node;
	}
	
	/// @desc	Updates a branch of nodes starting at the specified node and working up
	///			to the root.
	static update_branch = function(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return;
		}
		
		while (not is_undefined(node)){
			BVH.update_node(node);
			node = node.parent;
		}
	}
	
	static calculate_collision_aabb_array = function(node, data){
		if (not aabb_intersects_aabb(data.aabb, node.aabb))
			return [];
		
		if (node.get_is_leaf())
			return node.data_array;
			
		var array_left = BVH.calculate_collision_aabb_array(node.child_array[0], data);
		var array_right = BVH.calculate_collision_aabb_array(node.child_array[1], data);
		return array_concat(array_left, array_right);
	}
	
	static calculate_collision_ray_array = function(node, data){
		if (not ray_intersects_aabb(data.aabb.position, data.ray, node.aabb))
			return [];
		
		if (node.get_is_leaf())
			return node.data_array;
			
		var array_left = BVH.calculate_collision_ray_array(node.child_array[0], data);
		var array_right = BVH.calculate_collision_ray_array(node.child_array[1], data);
		return array_concat(array_left, array_right);
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
	
	function get_data_array(){
		var node_array = get_node_array();
		var array = array_create(array_length(node_array));
		for (var i = array_length(array) - 1; i >= 0; --i)
			array[i] = node_array[i].data_array;
		
		return array_concat(array_flatten(array), node_infinite.data_array);
	}
	
	/// @desc	Scans collisions for the specified piece of data. If a node is specified,
	///			it starts there. If not it starts at the partition root node.
	function scan_collisions(data, node=undefined){
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return [];
		}
		
		
		var array = [];
		if (data.data_shape == PARTITION_DATA_SHAPE.aabb)
			 array = BVH.calculate_collision_aabb_array(node ?? node_root, data);
		else if (data.data_shape == PARTITION_DATA_SHAPE.ray)
			array = BVH.calculate_collision_ray_array(node ?? node_root, data);
		
		array = array_concat(array, node_infinite.data_array);
		
		return array;
	}
	
	/// @desc	Attempts to add a piece of data to the tree; scanning nodes as
	///			appropriate and spawning / adjusting as necessary.
	super.register("add_data")
	function add_data(data){
		if (not super.execute("add_data", [data]))
			return false;
			
		if (data.data_shape == PARTITION_DATA_SHAPE.infinite){ // Special-case
			node_infinite.add_data(data);
			return;
		}
			
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
				BVH.push_data(node, data);
				BVH.update_branch(node);
				return true;
				
			}
			else { // Process down the children
				if (sa_left_adj < sa_right_adj) // Left wins
					node = node.child_array[0];
				else // Right wins
					node = node.child_array[1];
			}
		}
		
		// Add the data to the final node:
		node.add_data(data);
		
		if (node.get_data_count() > self.instance_max and node.depth > 0)
			BVH.split_node(node);

		BVH.update_branch(node);
			
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
		
		if (data.data_shape == PARTITION_DATA_SHAPE.infinite)
			return;
		
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

	function optimize(){
		BVH.balance_node(node_root);
	}

	function render_debug(){
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