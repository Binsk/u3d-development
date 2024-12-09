/// @about
/// This is a very simple unsorted 'partitioning' system that can be used when partitioning
/// isn't required. This is the default system used with rendering and collisions unless
/// something else is specified and is generally only useful for extremely small-scale
/// situations.

function Unsorted() : Partition() constructor {
	#region PROPERTIES
	self.node_root = new PartitionNode(self);
	#endregion
	
	#region METHODS
	
	function get_node_array(){
		return [node_root];
	}
	
	super.register("add_data");
	function add_data(data){
		if (not super.execute("add_data", [data]))
			return false;
		
		self.node_root.add_data(data);
	}
	
	super.register("remove_data");
	function remove_data(data){
		if (not super.execute("remove_data", [data]))
			return false;
		
		self.node_root.remove_data(data);
	}
	
	function scan_collisions(data){
		if (is_undefined(data))
			return [];
		
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return [];
		}
		debug_scan_count = 1;
		return array_duplicate_shallow(node_root.data_array);
	}
	
	function render_debug(){
		// We don't actually need the AABB in an unsorted structure so we just update
		// it when debug rendering for a size visual.
		node_root.aabb = node_root.calculate_child_data_aabb();
		node_root.render_debug();
	}
	
	#endregion
	
	#region INIT
	#endregion
}