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

function array_dot(a1, a2){
	var value = 0;
	for (var i = array_length(a1) - 1; i >= 0; --i)
		value += a1[i] * a2[i];
	
	return value;
}

function array_clamp(array, min_array, max_array){
	if (array_length(min_array) < array_length(array))
		throw new Exception("cannot clamp array, minimum array is invalid size.");
	
	if (array_length(max_array) < array_length(array))
		throw new Exception("cannot clamp array, minimum array is invalid size.");
	
	for (var i = array_length(array) - 1; i >= 0; --i)
		array[i] = clamp(array[i], min_array[i], max_array[i]);
	
	return array;
}