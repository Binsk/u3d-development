/// @about
/// A number of generic global math functions.

/// @desc	Returns the value furthest away from 0.
function abs_max(value1, value2){
	if (abs(value1) >= abs(value2))
		return value1;
	
	return value2;
}

/// @desc	Returns the value closest to 0.
function abs_min(value1, value2){
	if (abs(value1) <= abs(value2))
		return value1;
	
	return value2;
}

/// @desc	Performs a modulo wrap between [0..wrap) instead of
/// 		the regular (-wrap..wrap)
function modwrap(value, wrap){
	value %= wrap; // Normal wrap
	
	// Reverse wrap:
	if (value < 0){
		var nvalue = abs(value) % wrap;
		value = wrap - nvalue;
	}
	
	return value;
}

/// @desc	Returns if the specified value is in a set range
function in_range(value, minimum, maximum, min_inclusive=true, max_inclusive=true){
	var nvalue = clamp(value, minimum, maximum);
	if (not min_inclusive and nvalue <= minimum)
		return false;
	
	if (not max_inclusive and nvalue >= maximum)
		return false
	
	return (value == nvalue);
}

/// @desc	Returns the signed overlapping interval between two sets of values.
///			If no overlap occurs then 'undefined' is returned.
///			Direction returned is the amount to push the y interval.
function get_interval(x1, x2, y1, y2){
	var max_x = max(x1, x2);
	var max_y = max(y1, y2);
	var min_x = min(x1, x2);
	var min_y = min(y1, y2);
	
	var is_overlap = (min_x < max_y and min_y < max_x);
	if (not is_overlap)
		return undefined;
	
	var delta = min(max_x, max_y) - max(min_x, min_y);
	if (min(max_x, max_y) == max_x)
		return -delta;
	
	return delta;
}