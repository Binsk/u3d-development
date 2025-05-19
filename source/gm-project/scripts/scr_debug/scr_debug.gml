/// @desc	Returns an array of strings containing a hash + ref count.
///			Used to debug the number of references contained in the system.
function debug_get_reference_counts(){
	var keys = struct_get_names(U3D.MEMORY);
	var array = array_create(array_length(keys), "");
	for (var i = array_length(keys) - 1; i >= 0; --i)
		array[i] = $"{keys[i]} : {U3D.MEMORY[$ keys[i]].count}";
	
	return array;
}