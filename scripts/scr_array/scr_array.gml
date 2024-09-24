/// @about
/// Contains several generic array functions.

/// @desc	Creates a shallow copy of the specified array and returns the result.
function array_duplicate_shallow(array, offset=0, count=-1){
	if (count < 0)
		count = array_length(array) - offset;
	
	var narray = array_create(count);
	var nindex = count - 1;
	
	for (var i = offset + count - 1; i >= offset; --i)
		narray[nindex--] = array[i];
	
	return narray;
}

/// @desc	Glues elements of the array into one string and returns the result
function array_glue(glue, array, offset=0, count=-1){
	if (count < 0)
		count = max(0, count + array_length(array) - offset);
	
	var str = "";
	for (var i = offset; i <= count; ++i){
		if (i > offset)
			str += glue;
		
		str += string(array[i]);
	}
	
	return str;
}