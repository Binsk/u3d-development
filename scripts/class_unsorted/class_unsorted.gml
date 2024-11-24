/// @about
/// This is a very simple unsorted 'partitioning' system that can be used when partitioning
/// isn't required. This is the default system used with rendering and collisions unless
/// something else is specified.
function Unsorted() : Partition() constructor {
	#region PROPERTIES
	data_struct = {};
	scan_cache = undefined;	// Because it must scan the data struct per-body, it is faster to keep a cache
	#endregion
	
	#region METHODS
	super.register("add_data");
	function add_data(data){
		if (not super.execute("add_data", [data]))
			return false;
		
		data_struct[$ data] = data;
		scan_cache = undefined;
	}
	
	super.register("remove_data");
	function remove_data(data){
		if (not super.execute("remove_data", [data]))
			return false;
		
		struct_remove(data_struct, data);
		scan_cache = undefined;
	}
	
	function scan_collisions(data){
		if (is_undefined(data))
			return [];
		
		if (not is_instanceof(data, PartitionData)){
			Exception.throw_conditional("invalid type, expected [PartitionData]!");
			return [];
		}
		
		if (is_undefined(scan_cache))
			scan_cache = struct_get_values(data_struct); 
			
		return scan_cache;
	}
	#endregion
	
	#region INIT
	#endregion
}