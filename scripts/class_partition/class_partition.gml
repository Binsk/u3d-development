/// @about
/// A generic partitioning class that defines the interaction functions
/// that are common among all space partitioning algorithms. This provides an easy
/// way to swap out partitioning systems without needing to adjust any calling
/// functions.

/// @note	Partitioning systems should be able to have either methods or 
///			struct type definitions that define how data is handled. This way
///			a user can wrap a generic piece of data and have it handled properly.

function Partition() : U3DObject() constructor {
	#region PROPERTIES
	super = new Super(self);
	debug_scan_count = 0;	// Debugging value that records last scan count of a collision check 
	#endregion
	
	#region METHODS
	/// @desc	Should return all PartitionNode structures in the partition.
	function get_node_array(){
		return [];
	}
	
	/// @desc	Should return all PartitionData structures in the partition.
	function get_data_array(){
		var node_array = get_node_array();
		var array = array_create(array_length(node_array));
		for (var i = array_length(array) - 1; i >= 0; --i)
			array[i] = node_array[i].data_array;
		
		return array_flatten(array);
	}
	
	/// @desc	Add a piece of data to the partitioning system. Returns if successful.
	/// @param	{PartitionData}	data		data to add
	function add_data(data){
		if (is_undefined(data))
			return false;
			
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return false;
		}
		
		return true;
	}
	
	/// @desc	Removes a piece of data from the partitioning system. Returns if successful.
	/// @param	{PartitionData} data		data to remove
	function remove_data(data){
		if (is_undefined(data))
			return false;
			
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return false;
		}
		
		return true;
	}
	
	/// @desc	Updates a piece of data; usually because of motion, rotation, or scale.
	function update_data(data){
		// Fall-back 'update' if the structure doesn't implement one since re-adding will
		// generally re-calculate part of the structure.
		remove_data(data);
		add_data(data);
	}
	
	/// @desc	Scan the structure for node intersections and returns an array of all
	///			PartitionData structures that POTENTIALLY intersect; based on the node structure.
	/// @param	{PartitionData}	data	data to act as the collider
	function scan_collisions(data){
		return get_data_array();
	}
	
	/// @desc	Attempts to prune (or optimize) the partitioning structure. Should return 
	///			a > 0 value if prunning occurred.
	function optimize(){
		return 0;
	}
	
	/// @desc	Completely reconstructs the entire structure.
	function reconstruct(){
		var data_array = get_data_array();
		for (var i = array_length(data_array) - 1; i >= 0; --i)
			remove_data(data_array[i]);
			
		for (var i = array_length(data_array) - 1; i >= 0; --i)
			add_data(data_array[i]);
	}
	
	/// @desc	Should render out the structure as a 3D line primitive; which will be
	///			called by the Camera when debugging is enabled.
	function render_debug(){};
	#endregion
	
	#region INIT
	#endregion
}