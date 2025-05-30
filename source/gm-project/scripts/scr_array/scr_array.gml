/// @about
/// Contains several generic array functions.

/// @desc	Creates a shallow copy of the specified array and returns the result.
function array_duplicate_shallow(array, offset=0, count=-1){
	if (count < 0)
		count = array_length(array) - offset;
	
	if (count == 0)
		return [];
	
	var narray = array_create(count);
	var nindex = count - 1;
	
	for (var i = offset + count - 1; i >= offset; --i)
		narray[nindex--] = array[i];
	
	return narray;
}

/// @desc	Glues elements of the array into one string and returns the result.
///			Effectively string_join_ext().
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

/// @desc	Treats all the values in the array as an N-dimensional vector and
///			normalizes the result.
function array_normalize(array){
	var value = 0;
	for (var i = 0; i < array_length(array); ++i)
		value += sqr(array[i]);
	
	if (value <= 0 or is_nan(value))
		return array_create(array_length(array), 0);
		
	var m = sqrt(value);
	for (var i = 0; i < array_length(array); ++i)
		array[i] /= m;
	
	return array;
}

/// @desc	Executes 'callable' over each element of the array and replaces the
///			value in the array with the value returned by the callable. The callable
///			will be provided with 1 argument, the value from the array.
function array_execute(array, callable){
	if (not is_array(array))
		throw new Exception("invalid type, expected [array]!");
	
	if (not is_instanceof(callable, Callable))
		throw new Exception("invalid type, expected [Callable]!");
	
	for (var i = array_length(array) - 1; i >= 0; --i)
		callable.call([array[i]]);
	
	return array;
}

/// @desc	Treats a1 and a2 like n-dimentional vectors and calculates the dot-product.
/// 		Both arrays MUST be the same size.
function array_dot(a1, a2){
	var value = 0;
	for (var i = array_length(a1) - 1; i >= 0; --i)
		value += a1[i] * a2[i];
	
	return value;
}

/// @desc	Performs a per-component clamp over the array. All arrays MUST be the same size.
function array_clamp(array, min_array, max_array){
	if (array_length(min_array) < array_length(array))
		throw new Exception("cannot clamp array, minimum array is invalid size.");
	
	if (array_length(max_array) < array_length(array))
		throw new Exception("cannot clamp array, minimum array is invalid size.");
	
	for (var i = array_length(array) - 1; i >= 0; --i)
		array[i] = clamp(array[i], min_array[i], max_array[i]);
	
	return array;
}

/// @desc	Takes a nested array and flattens it into a single 1D array. Does not check
///			for recursive references but DOES flatten recursively.
function array_flatten(array){
	var narray = array_create(array_length_nested(array));
	
	var write_offset = 0;
	var loop = array_length(array);
	for (var i = 0; i < loop; ++i){
		if (not is_array(array[i])){
			narray[write_offset++] = array[i];
			continue;
		}
		
		var subarray = array_flatten(array[i]);
		var loop2 = array_length(subarray);
		for (var j = 0; j < loop2; ++j)
			narray[write_offset++] = subarray[j];
	}
	
	return narray;
}

/// @desc	Returns the total number of elements in a nested array. Does not check
///			for recursive references but does count elements recursively.
function array_length_nested(array){
	var count = array_length(array);
	for (var i = count - 1; i >= 0; --i){
		if (is_array(array[i]))
			count += array_length_nested(array[i]) - 1;
	}
	
	return count;
}

/// @desc	Makes a shallow copy of a struct.
function struct_duplicate_shallow(struct){
	if (not is_struct(struct))
		return undefined;
		
	var keys = struct_get_names(struct);
	var nstruct = {};
	for (var i = array_length(keys) - 1; i >= 0; --i)
		struct_set(nstruct, keys[i], struct[$ keys[i]]);
		
	return nstruct;
}