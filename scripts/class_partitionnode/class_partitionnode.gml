/// ABOUT
/// The PartitionNode is a special class used internally by the partitioning system.
/// It is a generic container that represents an axis-aligned area of space within
/// the partitioning structure.

function PartitionNode(position=vec(), extends=vec()) constructor {
	#region PROPERTIES
	static INDEX_COUNTER = int64(0);
	index = INDEX_COUNTER++;
	
	self.position = position;
	self.extends = extends;
	child_array = [];	// Array of child PartitionNodes (usage depends on partition type)
	data_array = [];	// Array of partition data assigned to this node
	#endregion
	
	#region METHODS
	function add_child(node){
		if (not is_instanceof(node, PartitionNode))
			throw new Exception("invalid type, expected [PartitionNode]!");
			
		for (var i = array_length(child_array) - 1; i >= 0; --i){
			if (child_array[i].index == node.index)
				return false;
		}
		
		array_push(child_array, node);
	}
	#endregion
}