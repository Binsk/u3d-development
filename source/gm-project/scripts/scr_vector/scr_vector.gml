/// @about
/// Defines a number of scripts dealing with 3D mathematical vectors.

/// @desc	Generates a new vector
function vec(x=0, y=0, z=0){
	return {
		x, y, z
	}
}

/// @desc	Returns if the specified value is a 3D vec().
function is_vec(value){
	if (not is_struct(value))
		return false;
	
	if (struct_names_count(value) != 3)
		return false;
	
	if (is_undefined(value[$ "x"]))
		return false;
	
	if (is_undefined(value[$ "y"]))
		return false;
	
	if (is_undefined(value[$ "z"]))
		return false;
	
	return true;
}

/// @desc	Creates a copy of the specified vector.
function vec_duplicate(vector){
	return vec(vector.x, vector.y, vector.z);
}

/// @desc	A convenient container to represent a vec + angle of rotation in 
///			radians. Generally should not be processed directly, but can be used
///			to transfer data between functions easily.
/// @param	{real}	x
/// @param	{real}	y
/// @param	{real}	z
/// @param	{real}	angle	angle to rotate around the vector components, in radians.
function veca(x=0, y=0, z=0, a=0){
	return {
		x, y, z, a
	};
}

/// @desc	A container that represents a vector + angle.
/// @param	{vec}	vector		vector to rotate around
/// @param	{real}	angle		number of radians to rotate
function vec_to_veca(vector=vec(), a=0){
	return {
		x : vector.x,
		y : vector.y,
		z : vector.z,
		a
	}
}

/// @desc	Takes a vector + angle and returns just the vec() component
function veca_to_vec(veca){
	return vec(veca.x, veca.y, veca.z);
}

///	@desc	Returns the cross product between the two vectors.
///	@param	{vec}	vector1		vector a to multiply
///	@param	{vec}	vector2		vector b to multiply
function vec_cross(v1, v2) {
	return vec( v1.y * v2.z - v1.z * v2.y,
				v1.z * v2.x - v1.x * v2.z,
				v1.x * v2.y - v1.y * v2.x);
}

/// @desc	Return the dot-product between two vectors.
function vec_dot(v1, v2){
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

/// @desc	Subtract v2 components from v1.
function vec_sub_vec(v1, v2){
	return vec(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
}


/// @desc	Add vector components together.
function vec_add_vec(v1, v2){
	return vec(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

/// @desc	Multiplies components of two vectors directly across.
function vec_mul_vec(v1, v2){
	return vec(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z);
}

/// @desc	Divides v1 components by v2 components directly across.
function vec_div_vec(v1, v2){
	return vec(v1.x / v2.x, v1.y / v2.y, v1.z / v2.z);
}

/// @desc	Peforms the same as vec_div_vec, only if the divisor is
/// 		the specified 'val' then that value will be returned instead
/// 		of the division.
function vec_div2_vec(v1, v2, val=0){
	return vec(v2.x == 0 ? val : v1.x / v2.x, v2.y == 0 ? val : v1.y / v2.y, v2.z == 0 ? val : v1.z / v2.z);
}

/// @desc	Applies abs() to each component of the vector and returns the result
function vec_abs(v){
	return vec(abs(v.x), abs(v.y), abs(v.z));
}

/// @desc	Applies -abs() to each component of the vector and returns the result
function vec_nabs(v){
	return vec(-abs(v.x), -abs(v.y), -abs(v.z));
}

/// @desc	Applies sign() to each componenent of the vector and returns the result
function vec_sign(v){
	return vec(sign(v.x), sign(v.y), sign(v.z));
}

/// @desc	Applies clamp() to each component of the vector and returns the result
/// @param	{vec}	vector	vector to modify
/// @param	{vec}	min		vector containing minimum components
/// @param	{vec}	max		vector containing maximum components
function vec_clamp(v, vm, vM){
	return vec(
		clamp(v.x, vm.x, vM.x),
		clamp(v.y, vm.y, vM.y),
		clamp(v.z, vm.z, vM.z)
	);
}

/// @desc	Applies func() to each component of the vector and returns the result
function vec_iterate(vector, func){
	return vec(func(vector.x), func(vector.y), func(vector.z));
}

/// @desc	Multiplies each component of a vector by a scalar
function vec_mul_scalar(v1, scalar){
	return vec(v1.x * scalar, v1.y * scalar, v1.z * scalar);
}

/// @desc	Adds a scalar to each component in the vector.
function vec_add_scalar(v1, scalar){
	return vec(v1.x + scalar, v1.y + scalar, v1.z + scalar);
}

/// @desc	Returns the specified vector with the length of 1.
function vec_normalize(v){
	var m = vec_magnitude(v);
	if (m == 0)
		return vec(0, 0, 0);
		
	return vec(v.x / m, v.y / m, v.z / m);
}

/// @desc	Returns the specified vector with a new length.
function vec_set_length(v, length){
	return vec_mul_scalar(vec_normalize(v), length);
}

/// @desc	Returns the length of the vector.
function vec_magnitude(v){
	return sqrt(sqr(v.x) + sqr(v.y) + sqr(v.z));
}

/// @desc	Returns if any component of the vector is NaN.
function vec_is_nan(v){
	if (is_nan(v.x))
		return true;
	if (is_nan(v.y))
		return true;
	if (is_nan(v.z))
		return true;
	
	return false;
}

/// @desc	Given a vec, returns an array of 3 values in the order of [x, y, z]
function vec_to_array(vector){
	return [
		vector.x, vector.y, vector.z
	];
}

/// @desc	Rotates the specified vector around an arbitrary axis by a number of radians
/// @param	{vec}	vector 		vector to be rotated
/// @param	{vec}	axis		vector to be rotated around
/// @param	{real}	angle		number of radians to rotate by
function vec_rotate(vector, axis, radians) {
	var par = vec_mul_scalar(axis, vec_dot(vector, axis) / vec_dot(axis, axis));
	var perp = vec_sub_vec(vector, par);

	if (vec_magnitude(perp) <= 0) // Nothing to rotate
		return vector;
	
	// Find orth vector:
	var orth = vec_cross(axis, perp);

	if (vec_magnitude(orth) <= 0) // Nothing to rotate
		return vector;
	
	// Calculate linear combination:
	var s1 = cos(radians) / vec_magnitude(perp);
	var s2 = sin(radians) / vec_magnitude(orth);

	var lin = vec_add_vec(  vec_mul_scalar(perp, s1),
							vec_mul_scalar(orth, s2));
	lin = vec_mul_scalar(lin, vec_magnitude(perp));

	return vec_add_vec(lin, par);
}

/// @desc	Returns the number of radians to get from vector1 to vector2.
/// 		The result is NOT SIGNED and will always be positive.
function vec_angle_difference(vector1, vector2) {
	vector1 = vec_normalize(vector1);
	vector2 = vec_normalize(vector2);
	return arccos(vec_dot(vector1, vector2));
}

/// @desc	Returns the inverse of the specified vector. The vector's components
/// 		should generally be between [0..1]
function vec_invert(vector){
	return vec(
		vector.x == 0 ? infinity : 1.0 / vector.x,
		vector.y == 0 ? infinity : 1.0 / vector.y,
		vector.z == 0 ? infinity : 1.0 / vector.z
	);
}

/// @desc	Retruns a copy of the vector with each component's sign reversed.
function vec_reverse(vector){
	return vec(
		-vector.x,
		-vector.y,
		-vector.z
	);
}

/// @desc	Lerps components across from one vector to another.
/// @param	{vec}	from	vector to lerp from
/// @param	{vec}	to		vector to lerp to
/// @param	{real}	lerp	percentage to lerp between vectors
function vec_lerp(vector1, vector2, percent){
	return vec(
		lerp(vector1.x, vector2.x, percent),
		lerp(vector1.y, vector2.y, percent),
		lerp(vector1.z, vector2.z, percent)
	);
}

/// @desc	Performs a spherical lerp between two vectors. Each
/// 		vector must be normalized.
/// @param	{vec}	from	vector to lerp from
/// @param	{vec}	to		vector to lerp to
/// @param	{real}	lerp	percentage to lerp between vectors
function vec_slerp(vector1, vector2, percent) {
	percent = clamp(percent, 0, 1);
	var dot = vec_dot(vector1, vector2);
	if (dot < 0.0){ // Work around "long path" issue
		dot = -dot;
		vector2 = vec_invert(vector2);
	}
	
		// If values are almost the same, use lerp instead as we would get issues:
	if (dot > 0.9995)
		return vec_normalize(vec_lerp(vector1, vector2, percent));
		
	var angle = arccos(dot);	// Angle  between two vectors
	var angle_partial = angle * percent; // Angle between vector1 and final vector

	var angle_sin = sin(angle);
	var angle_sin_partial = sin(angle_partial);

	var scalar_vec1 = cos(angle_partial) - dot * angle_sin_partial / angle_sin,
		scalar_vec2 = angle_sin_partial / angle_sin;
	
	return vec_add_vec(	vec_mul_scalar(vector1, scalar_vec1), 
						vec_mul_scalar(vector2, scalar_vec2));


}

/// @desc	Projects a vector onto a normal (effectively removing that axis from the vector)
///			The normal should be normalized.
function vec_project(vector, normal){
	var dot = vec_dot(vector, normal); // Magnitude of vector along the normal
	var normal_mag = vec_mul_scalar(normal, dot);
	return vec_sub_vec(vector, normal_mag);
}

/// @desc	Reflects the vector against the specified normal as if 'bouncing' off a surface
///			where the normal is the direction of the surface. Normal must be normalized.
function vec_reflect(vector, normal){
	var length = vec_magnitude(vector);
	return vec_sub_vec(vector, vec_mul_scalar(normal, 2 * vec_dot(vector, normal)));
}

/// @desc	Returns an arbitrary perpendicular vector to the one specified.
function vec_get_perpendicular(vector){
	if (vector.x == 0 and vector.y == 0){
		if (vector.z == 0){
			Exception.throw_conditional("cannot calculate perpendicular vector for zero-vector!");
			return vec();
		}
		
		return vec(0, vector.z, 0);
	}
	
	return vec(vector.x, vector.z, -vector.y);
}

/// @desc	Returns if the specified vector contains only values of 0.
function vec_is_zero(vector){
	return (vector.x == 0 and vector.y == 0 and vector.z == 0);
}

/// @desc	Returns if the two vectors are mathematically equal.
function vec_equals_vec(v1, v2){
	if (v1.x != v2.x)
		return false;
	
	if (v1.y != v2.y)
		return false;
	
	if (v1.z != v2.z)
		return false;
	
	return true;
}

/// @desc	Performs a 'step' on each component of the vector where 0 is returned
/// 		if the threshold is not met and 1 is returned if the threshold is met.
/// @param	{vec}	vector	vector to step
/// @param	{real}	edge	cutoff threshold
function vec_step(vector, edge){
	return vec(
		vector.x < edge.x ? 0 : 1,
		vector.y < edge.y ? 0 : 1,
		vector.z < edge.z ? 0 : 1
	);
}

/// @desc	Takes the smallest component of each vector.
function vec_min(vector1, vector2){
	return vec(
		min(vector1.x, vector2.x),
		min(vector1.y, vector2.y),
		min(vector1.z, vector2.z)
	);
}

/// @desc	Takes the larger component of each vector.
function vec_max(vector1, vector2){
	return vec(
		max(vector1.x, vector2.x),
		max(vector1.y, vector2.y),
		max(vector1.z, vector2.z)
	);
}

/// @desc	Returns the vector with the smallest magnitude.
function vec_min_magnitude(){
	var min_length = infinity;
	var min_vec = undefined;
	for (var i = 0; i < argument_count; ++i){
		var length = vec_magnitude(argument[i]);
		if (length < min_length){
			min_length = length;
			min_vec = argument[i];
		}
	}
	
	return min_vec;
}

/// @desc	Returns the vector with the largest magnitude.
function vec_max_magnitude(){
	var max_length = -infinity;
	var max_vec = undefined;
	for (var i = 0; i < argument_count; ++i){
		var length = vec_magnitude(argument[i]);
		if (length > max_length){
			max_length = length;
			max_vec = argument[i];
		}
	}
	
	return max_vec;
}

/// @desc	Determines the largest abs value of each component and keeps it, along with
///			the sign.
function vec_abs_max(vector1, vector2){
	return vec(
		abs_max(vector1.x, vector2.x),
		abs_max(vector1.y, vector2.y),
		abs_max(vector1.z, vector2.z)
	);
}

/// @desc	Returns the smallest component in the vector.
function vec_min_component(vector){
	return min(vector.x, vector.y, vector.z);
}

/// @desc	Returns the largest component in the vector.
function vec_max_component(vector){
	return max(vector.x, vector.y, vector.z);
}


/// @desc	A bit of a hack to easily convert a 3-component struct to a color. Done
///			to simplify color data loading in the glTF loader.
function vec_to_color(vector){
	return make_color_rgb(vector.x * 255, vector.y * 255, vector.z * 255);
}

