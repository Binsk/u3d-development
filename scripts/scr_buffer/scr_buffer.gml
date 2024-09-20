/// @desc	Writes an array of values into the buffer at the current
/// 		  seek position. Returns the current tell after writing, or
/// 		  -1 if there was a problem with one of the writes.
function buffer_write_series(buffer, type, array){
	var loop = array_length(array);
	for (var i = 0; i < loop; ++i){
		if (buffer_write(buffer, type, array[i]) != 0)
			return -1;
	}
	return buffer_tell(buffer);
}

/// @desc	Reads a number of values from a buffer at the current
/// 		  seek position and returns them as an array.
function buffer_read_series(buffer, type, count){
	var array = array_create(count, 0);
	for (var i = 0; i < count; ++i)
		array[i] = buffer_read(buffer, type);
	
	return array;
}