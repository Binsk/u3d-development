var partition_array = struct_get_values(partition_layers);
for (var i = array_length(partition_array) - 1; i >= 0; --i){
	partition_array[i].free();
	delete partition_array[i];
}