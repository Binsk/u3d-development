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
	#endregion
	
	#region METHODS
	function add_data(data){
		if (is_undefined(data))
			return false;
			
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return false;
		}
		
		return true;
	}
	
	function remove_data(data){
		if (is_undefined(data))
			return false;
			
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return false;
		}
		
		return true;
	}
	
	/// @desc	Scan the structure for node intersections and returns an array of all
	///			data that is contained within the intersecting nodes.
	/// @param	{PartitionData}	data	data to scan
	function scan_collisions(data){
		return [];
	}
	#endregion
	
	#region INIT
	#endregion
}