/// @desc	Calculate the determinant of the specified matrix.
function matrix_get_determinant(matrix) {
	var determinant = 0;
	var a11 = matrix[0],
    a12 = matrix[1],
    a13 = matrix[2],
    a14 = matrix[3],

    a21 = matrix[4],
    a22 = matrix[5],
    a23 = matrix[6],
    a24 = matrix[7],

    a31 = matrix[8],
    a32 = matrix[9],
    a33 = matrix[10],
    a34 = matrix[11],

    a41 = matrix[12],
    a42 = matrix[13],
    a43 = matrix[14],
    a44 = matrix[15];

	determinant =	a11 * a22 * a33 * a44 +
					a11 * a23 * a34 * a42 +
					a11 * a24 * a32 * a43 +
					
					a12 * a21 * a34 * a43 +
					a12 * a23 * a31 * a44 +
					a12 * a24 * a33 * a41 +
					
					a13 * a21 * a32 * a44 +
					a13 * a22 * a34 * a41 +
					a13 * a24 * a31 * a42 +
					
					a14 * a21 * a33 * a42 +
					a14 * a22 * a31 * a43 +
					a14 * a23 * a32 * a41;
                
	    // Part two:
	determinant +=	-a11 * a22 * a34 * a43
					-a11 * a23 * a32 * a44
					-a11 * a24 * a33 * a42
					
					-a12 * a21 * a33 * a44
					-a12 * a23 * a34 * a41
					-a12 * a24 * a31 * a43
					
					-a13 * a21 * a34 * a42
					-a13 * a22 * a31 * a44
					-a13 * a24 * a32 * a41
					
					-a14 * a21 * a32 * a43
					-a14 * a22 * a33 * a41
					-a14 * a23 * a31 * a42;
                 
	return determinant;
}

/// @desc	Returns the transpose of the specified matrix as if it has
///			been rotated 180 degrees across its diagonal.
function matrix_get_transpose(matrix){
	return[matrix[0], matrix[4], matrix[8], matrix[12],
		   matrix[1], matrix[5], matrix[9], matrix[13],
		   matrix[2], matrix[6], matrix[10], matrix[14],
		   matrix[3], matrix[7], matrix[11], matrix[15]];
}

/// @desc	Returns the translation component as a vector.
function matrix_get_translation(matrix){
	return vec(matrix[12], matrix[13], matrix[14]);
}

/// @desc	Takes a GameMaker matrix and returns a quaternion that applies the
///			rotation and scale. The matrix must have an equal scale across all
///			axes. The quaternion will not be normalized if there is scale.
///			If the matrix has unequal scales then the quaternion will be incorrect.
function matrix_get_quat(matrix){
	var det = power(matrix_get_determinant(matrix), 1/3);
	var quaternion = quat(
		-sqrt(max(0, det + matrix[0] - matrix[5] - matrix[10])) * 0.5,
		-sqrt(max(0, det - matrix[0] + matrix[5] - matrix[10])) * 0.5,
		-sqrt(max(0, det - matrix[0] - matrix[5] + matrix[10])) * 0.5,
		-sqrt(max(0, det + matrix[0] + matrix[5] + matrix[10])) * 0.5
	);
	
	quaternion.x = abs(quaternion.x) * sign(matrix[9] - matrix[6]);
	quaternion.y = abs(quaternion.y) * sign(matrix[2] - matrix[8]);
	quaternion.z = abs(quaternion.z) * sign(matrix[4] - matrix[1]);
	
	return quaternion;
}

/// @desc	Given a scaling vector, builds a scaling matrix
/// @param	{vec}	scale
function matrix_build_scale(s){
	var matrix = matrix_build_identity();
	matrix[0] = s.x;
	matrix[5] = s.y;
	matrix[10] = s.z;
	return matrix;
}

/// @desc	Given a positional vector, builds a translation matrix.
/// @param	{vec}	translation
function matrix_build_translation(t){
	var matrix = matrix_build_identity();
	matrix[12] = t.x;
	matrix[13] = t.y;
	matrix[14] = t.z;
	return matrix;
}

/// @desc	Given a quaternion, generates a rotational matrix.
/// @param	{quat}	rotation
function matrix_build_quat(q){
	q = quat_normalize(q);
	
	var matrix = matrix_build_identity();
	
	matrix[0] = 1 - 2 * (sqr(q.y) + sqr(q.z));
	matrix[1] = 2 * (q.x * q.y + q.z * q.w);
	matrix[2] = 2 * (q.x * q.z - q.y * q.w);
	
	matrix[4] = 2 * (q.x * q.y - q.z * q.w);
	matrix[5] = 1 - 2 * (sqr(q.x) + sqr(q.z));
	matrix[6] = 2 * (q.y * q.z + q.x * q.w);
	
	matrix[8] = 2 * (q.x * q.z + q.y * q.w);
	matrix[9] = 2 * (q.y * q.z - q.x * q.w);
	matrix[10] = 1 - 2 * (sqr(q.x) + sqr(q.y));
	
	return matrix;
}

/// @desc	Takes an arbitrary number of matrices as arguments and post-multiplies
///			them together. E.g., if T * R * S is passed in, the result would
///			be (S * R) * T
function matrix_multiply_post(){
	var result = argument[argument_count - 1];
	for (var i = argument_count - 2; i >= 0; --i)
		result = matrix_multiply(result, argument[i]);
	
	return result;
}

/// @desc	Multiplies a vector against a GameMaker matrix, similar to
///			matrix_transform_vertex, only the w component will be discarded.
function matrix_multiply_vec(matrix, vector, w=0){
	var array = matrix_transform_vertex(matrix, vector.x, vector.y, vector.z, w);
	return vec(array[0], array[1], array[2]);
}

/// @desc	Converts a 4x4 GameMaker matrix into a 3x3 matrix, used to pass in
///			to a shader.
function matrix_to_matrix3(matrix){
	return [
		matrix[0], matrix[1], matrix[2],
		matrix[4], matrix[5], matrix[6],
		matrix[8], matrix[9], matrix[10]
	];
}

/// @desc	Returns if the specified matrix is the identity matrix.
function matrix_is_identity(matrix){
	var identity = matrix_build_identity();
	for (var i = array_length(identity) - 1; i >= 0; --i){
		if (matrix[i] != identity[i])
			return false;
	}
	
	return true;
}