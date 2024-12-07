/// @about
/// Contains a number of scripts dealing with 4D rotational quaternions.
/// The quaternion struct is also commonly used as a simple 4-value container
/// when passing data around to functions.

/// @desc	generates a new quaternion and returns the result.
///			Defaults to the identity quaternion.
function quat(x=0, y=0, z=0, w=1){
	return {
		x, y, z, w
	}
}

/// @desc	Returns if the specified value is a quaternion.
function is_quat(value){
	if (not is_struct(value))
		return false;
	
	if (struct_names_count(value) != 4)
		return false;
	
	if (is_undefined(value[$ "x"]))
		return false;
	
	if (is_undefined(value[$ "y"]))
		return false;
	
	if (is_undefined(value[$ "z"]))
		return false;
	
	if (is_undefined(value[$ "w"]))
		return false;
	
	return true;
}

/// @desc	Returns if the specified quaternion is the identity quaternion.
function quat_is_identity(quaternion){
	if (quaternion.x != 0)
		return false;
	
	if (quaternion.y != 0)
		return false;
		
	if (quaternion.z != 0)
		return false;
	
	if (quaternion.w != 1)
		return false;
	
	return true;
}

/// @desc	Returns if every value in the quaternion is zero.
function quat_is_zero(quaternion){
	if (quaternion.x != 0)
		return false;
	
	if (quaternion.y != 0)
		return false;
		
	if (quaternion.z != 0)
		return false;
	
	if (quaternion.w != 0)
		return false;
	
	return true;
}

/// @desc	Returns an array of 4 values in the order of [x, y, z, w].
function quat_to_array(quaternion){
	return [
		quaternion.x, quaternion.y, quaternion.z, quaternion.w
	];
}

/// @desc	Returns the length of the quaternion.
function quat_magnitude(quaternion){
	return sqrt(sqr(quaternion.x) + sqr(quaternion.y) + sqr(quaternion.z) + sqr(quaternion.w));
}

/// @desc	Retruns a version of the quaternion with a length of 1.
function quat_normalize(quaternion){
	var m = quat_magnitude(quaternion);
	return quat(quaternion.x / m, quaternion.y / m, quaternion.z / m, quaternion.w / m);
}

/// @desc	Returns the quaternion with all components sign's flipped.
function quat_reverse(quaternion){
	return quat(-quaternion.x, -quaternion.y, -quaternion.z, -quaternion.w);
}

/// @desc	Returns if two quaternions are mathematically identical.
function quat_equals_quat(q1, q2){
	if (abs(q1.x - q2.x) > 0)
		return false;
	
	if (abs(q1.y - q2.y) > 0)
		return false;
	
	if (abs(q1.z - q2.z) > 0)
		return false;
	
	if (abs(q1.w - q2.w) > 0)
		return false;
	
	return true;
}

/// @desc	Takes a quaternion and returns a vector + angle pair that
///			equates to the same rotation.
/// @note	If there is no rotation then we don't have a defined axis so
///			the resulting axis + angle will be the up vector and 0.
function quat_to_veca(quaternion){
	var angle = 2.0 * arccos(quaternion.w);
	
	if (angle == 0){
		return { // If 0, axis doesn't matter as there is no rotation
			vector : vec(0, 1, 0), // Could be anything; we chose y-up
			angle : 0
		};
	}
	
	/// @note	If angle == 180deg (or -180deg) the axis can flip-flop; if we
	///			want to catch that we could add that check here.
	var qws = sqrt(1.0 - sqr(quaternion.w));
	
	var vector = vec(
		quaternion.x / qws,
		quaternion.y / qws,
		quaternion.z / qws
	);
	
	return vec_to_veca(vector, angle);
}

/// @desc	Given an axis + angle pair, converts it into a 
///			quaternion rotation.
function veca_to_quat(vectora){
	var asin = sin(vectora.a * 0.5);
	var quaternion = quat(vectora.x * asin,
						  vectora.y * asin,
						  vectora.z * asin,
						  cos(vectora.a * 0.5));
	return quat_normalize(quaternion);
}

/// @desc	Given a directonal vector, returns the quaternion required to rotate
///			vec(1, 0, 0) to equal that vector. Note that there are a few cases
///			where this will fail! Namely if the forward and directional vectors
///			are exact opposites! It is better to use veca_to_quat when possible.
function vec_to_quat(vector){
	vector = vec_normalize(vector);
	if (vec_equals_vec(vector, Node.AXIS_FORWARD) or vec_is_zero(vector))
		return quat();	// Identity quat
	
	var rotation_axis;
	var rotation_angle;
	
	if (vec_equals_vec(vector, vec_reverse(Node.AXIS_FORWARD))){
		// If exactly opposite, attempt to rotate around an arbitrary perp vector.
		// This will NOT work consistently in all cases as it depends on the which
		// axes we are pointing.
		rotation_axis = vec_get_perpendicular(vector);
		rotation_angle = pi;
	}
	else {
		rotation_axis = vec_normalize(vec_cross(Node.AXIS_FORWARD, vector));
		rotation_angle = vec_angle_difference(Node.AXIS_FORWARD, vector);
	}
	
	return veca_to_quat(vec_to_veca(rotation_axis, rotation_angle));
}

/// @desc	Multiplies two quaternions together; this is the same as rotating quat2
///			by quat1.
function quat_mul_quat(quat1, quat2){
	return quat(
		quat1.w * quat2.x + quat1.x * quat2.w + quat1.y * quat2.z - quat1.z * quat2.y,
		quat1.w * quat2.y - quat1.x * quat2.z + quat1.y * quat2.w + quat1.z * quat2.x,
		quat1.w * quat2.z + quat1.x * quat2.y - quat1.y * quat2.x + quat1.z * quat2.w,
		quat1.w * quat2.w - quat1.x * quat2.x - quat1.y * quat2.y - quat1.z * quat2.z
	);
}

/// @desc	Given a rotation quaternion, returns a vector containing the required
///			euler angles (in radians) required to arrive at that same rotation when
///			executed in the ZXY order.
///				x - forward
///				y - up
///				z - right
function quat_to_euler(quat){
	var roll = 0, pitch = 0, yaw = 0;
	
	// Roll (x-axis):
	var s = 2 * (quat[3] * quat[0] - quat[1] * quat[2]) ;
	var c = 1 - 2 * (sqr(quat[0]) + sqr(quat[2]));
	roll = arctan2(s, c);
	
	// Pitch (z-axis):
	s = sqrt(1 + 2 * (quat[3] * quat[2] + quat[0] * quat[1]));
	c = sqrt(1 - 2 * (quat[3] * quat[2] + quat[0] * quat[1]));
	pitch = 2 * arctan2(s, c) - pi * 0.5;
	
	// Yaw (y-axis):
	s = 2 * (quat[3] * -quat[1] + quat[0] * quat[2]);
	c = 1 - 2 * (sqr(quat[2]) + sqr(quat[1]));
	yaw = arctan2(s, c);
	
	return vec(roll, yaw, -pitch);
}

/// @desc	Returns the conjugate of the specified quaternion.
function quat_get_conjugate(quaternion){
	return quat(-quaternion.x, -quaternion.y, -quaternion.z, quaternion.w);
}

/// @desc	Applies the quaternion rotation to the specified vector by calculating
///			v' = qvq'
function quat_rotate_vec(quaternion, vector){
	var quaternionc = quat_get_conjugate(quaternion); // Get the reverse op of the quat
	var vectorq = quat(vector.x, vector.y, vector.z, 0);	// 'Convert' the vector to a quaternion
		// Apply rotations to the vector
	var nquaternion = quat_mul_quat(quaternion, vectorq);	
	nquaternion = quat_mul_quat(nquaternion, quaternionc);
		// Remove the w component from the result and return as a vec()
	return vec(nquaternion.x, nquaternion.y, nquaternion.z);
}

/// @desc	Performs a spherical interpolation between two quaternions.
/// @param	{quat}	from	quaternion to rotate from
/// @param	{quat}	to		quaternion to rotate to
/// @param	{real}	lerp	lerp value to use between the two
function quat_slerp(q1, q2, time){
	q1 = quat_to_array(q1);
	q2 = quat_to_array(q2)
	var dot = array_dot(q1, q2);
	if (dot < 0){ // If < 0 invert so we rotate the shortest route
		q1[0] = -q1[0];
		q1[1] = -q1[1];
		q1[2] = -q1[2];
		q1[3] = -q1[3];
		dot = array_dot(q1, q2);
	}
	var angle = arccos(dot);
	var denom = sin(angle);
	if (denom == 0)
		return quat(q1[0], q1[1], q1[2], q1[3]);
	
	var s1 = sin((1 - time) * angle);
	var s2 = sin(time * angle);
	
	var q = quat(
		(q1[0] * s1 + q2[0] * s2) / denom,
		(q1[1] * s1 + q2[1] * s2) / denom,
		(q1[2] * s1 + q2[2] * s2) / denom,
		(q1[3] * s1 + q2[3] * s2) / denom
	);
	
	return quat_normalize(q);
}

/// @desc	Returns a mathematically identical quaternion to the one specified.
function quat_duplicate(quaternion){
	return quat(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
}