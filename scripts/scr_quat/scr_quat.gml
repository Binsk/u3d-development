/// ABOUT
/// Contains a number of scripts dealing with 4D rotational quaternions.
/// The quaternion struct is also commonly used as a simple 4-value container.

/// @desc	generates a new quaternion and returns the result.
function quat(x=0, y=0, z=0, w=1){
	return {
		x, y, z, w
	}
}

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

function quat_to_array(quaternion){
	return [
		quaternion.x, quaternion.y, quaternion.z, quaternion.w
	];
}

function quat_magnitude(quaternion){
	return sqrt(sqr(quaternion.x) + sqr(quaternion.y) + sqr(quaternion.z) + sqr(quaternion.w));
}

function quat_normalize(quaternion){
	var m = quat_magnitude(quaternion);
	return quat(quaternion.x / m, quaternion.y / m, quaternion.z / m, quaternion.w / m);
}

/// @desc	Takes a quaternion and returns a vector + angle pair.
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
		quaternion.z / qws,
	);
	
	return vec_to_veca(vector, angle);
}

/// @desc	Given an axis-angle, converts it into a quaternion.
function veca_to_quat(vector){
	var asin = sin(vector.a * 0.5);
	var quaternion = quat(vector.x * asin,
						  vector.y * asin,
						  vector.z * asin,
						  cos(vector.a * 0.5));
	return quat_normalize(quaternion);
}

/// @desc	Multiplies two quaternions together; this is the same as applying one
///			rotation over the other rotation.
function quat_mul_quat(quat1, quat2){
	return quat(
		quat1.w * quat2.x + quat1.x * quat2.w + quat1.y * quat2.z - quat1.z * quat2.y,
		quat1.w * quat2.y - quat1.x * quat2.z + quat1.y * quat2.w + quat1.z * quat2.x,
		quat1.w * quat2.z + quat1.x * quat2.y - quat1.y * quat2.x + quat1.z * quat2.w,
		quat1.w * quat2.w - quat1.x * quat2.x - quat1.y * quat2.y - quat1.z * quat2.z
	);
}

/// @desc	Given an axis to rotate around and an angle (in radians), determines the
///			euler angles to perform the same rotation. Assumes the axis is normalized
///			and that euler rotations are performed in the ZXY order with the following
///			axis layout:
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