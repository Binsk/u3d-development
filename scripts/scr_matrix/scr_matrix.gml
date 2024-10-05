/// @desc	Calculates the inverse of the specified matrix, or undefined if it cannot be calculated.
function matrix_get_inverse(matrix) {
	var matrix_inverse = array_create(15),
	var determinant = matrix_get_determinant(matrix);
	
	if (determinant == 0){
		Exception.throw_conditional("Failed to calculate inverse matrix. Determinant = 0!");
		return matrix;
	}

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

	// Calculate second base matrix:
	// [1, 1]
	matrix_inverse[0] = a22 * a33 * a44 +
	a23 * a34 * a42 +
	a24 * a32 * a43 -
	a22 * a34 * a43 -
	a23 * a32 * a44 -
	a24 * a33 * a42;
	
	//[1, 2]
	matrix_inverse[1] = a12 * a34 * a43 +
	a13 * a32 * a44 +
	a14 * a33 * a42 -
	a12 * a33 * a44 -
	a13 * a34 * a42 -
	a14 * a32 * a43;
	
	//[1, 3]
	matrix_inverse[2] = a12 * a23 * a44 +
	a13 * a24 * a42 +
	a14 * a22 * a43 -
	a12 * a24 * a43 -
	a13 * a22 * a44 -
	a14 * a23 * a42;
	
	//[1, 4]
	matrix_inverse[3] =  a12 * a24 * a33 +
	a13 * a22 * a34 +
	a14 * a23 * a32 -
	a12 * a23 * a34 -
	a13 * a24 * a32 -
	a14 * a22 * a33;
	
	//[2, 1]
	matrix_inverse[4] =  a21 * a34 * a43 +
	a23 * a31 * a44 +
	a24 * a33 * a41 -
	a21 * a33 * a44 -
	a23 * a34 * a41 -
	a24 * a31 * a43;
	
	//[2, 2]
	matrix_inverse[5] =  a11 * a33 * a44 +
	a13 * a34 * a41 +
	a14 * a31 * a43 -
	a11 * a34 * a43 -
	a13 * a31 * a44 -
	a14 * a33 * a41;
	
	//[2, 3]
	matrix_inverse[6] =  a11 * a24 * a43 +
	a13 * a21 * a44 +
	a14 * a23 * a41 -
	a11 * a23 * a44 -
	a13 * a24 * a41 -
	a14 * a21 * a43;
	
	//[2, 4]
	matrix_inverse[7] =  a11 * a23 * a34 +
	a13 * a24 * a31 +
	a14 * a21 * a33 -
	a11 * a24 * a33 -
	a13 * a21 * a34 -
	a14 * a23 * a31;
	
	//[3, 1]
	matrix_inverse[8] =  a21 * a32 * a44 +
	a22 * a34 * a41 +
	a24 * a31 * a42 -
	a21 * a34 * a42 -
	a22 * a31 * a44 -
	a24 * a32 * a41;
	
	//[3, 2]
	matrix_inverse[9] =  a11 * a34 * a42 +
	a12 * a31 * a44 +
	a14 * a32 * a41 -
	a11 * a32 * a44 -
	a12 * a34 * a41 -
	a14 * a31 * a42;
	
	//[3, 3]
	matrix_inverse[10] = a11 * a22 * a44 +
	a12 * a24 * a41 +
	a14 * a21 * a42 -
	a11 * a24 * a42 -
	a12 * a21 * a44 -
	a14 * a22 * a41;
	
	//[3, 4]
	matrix_inverse[11] = a11 * a24 * a32 +
	a12 * a21 * a34 +
	a14 * a22 * a31 -
	a11 * a22 * a34 -
	a12 * a24 * a31 -
	a14 * a21 * a32;
	
	//[4, 1]
	matrix_inverse[12] = a21 * a33 * a42 +
	a22 * a31 * a43 +
	a23 * a32 * a41 -
	a21 * a32 * a43 -
	a22 * a33 * a41 -
	a23 * a31 * a42;
	
	//[4, 2]
	matrix_inverse[13] = a11 * a32 * a43 +
	a12 * a33 * a41 +
	a13 * a31 * a42 -
	a11 * a33 * a42 -
	a12 * a31 * a43 -
	a13 * a32 * a41;
	
	//[4, 3]
	matrix_inverse[14] = a11 * a23 * a42 +
	a12 * a21 * a43 +
	a13 * a22 * a41 -
	a11 * a22 * a43 -
	a12 * a23 * a41 -
	a13 * a21 * a42;
	
	//[4, 4]
	matrix_inverse[15] = a11 * a22 * a33 +
	a12 * a23 * a31 +
	a13 * a21 * a32 -
	a11 * a23 * a32 -
	a12 * a21 * a33 -
	a13 * a22 * a31;
	
	// Multiply by determinant:
	determinant = 1 / determinant;
	
	for (var i = 0; i < 16; ++i)
		matrix_inverse[i] *= determinant;
	
	return matrix_inverse;
}

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

function matrix_get_transpose(matrix){
	return[matrix[0], matrix[4], matrix[8], matrix[12],
		   matrix[1], matrix[5], matrix[9], matrix[13],
		   matrix[2], matrix[6], matrix[10], matrix[14],
		   matrix[3], matrix[7], matrix[11], matrix[15]];
}

function matrix_build_scale(xs, ys, zs){
	var matrix = matrix_build_identity();
	matrix[0] = xs;
	matrix[5] = ys;
	matrix[10] = zs;
	return matrix;
}

function matrix_build_translation(tx, ty, tz){
	var matrix = matrix_build_identity();
	matrix[12] = tx;
	matrix[13] = ty;
	matrix[14] = tz;
	return matrix;
}