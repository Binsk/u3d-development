/// @about
/// Basic functionality between AABB shapes in a non-class format. Note that
/// this is SEPARATE from the CollidableAABB, as Collidables handle morphing 
/// and more complex functionality. These AABB functions are for fast on-the-spot
/// and simple AABB checks.

/// @desc	Creates a new AABB structure at the specified position with the given
///			extends.
/// @param	{vec}	position	position positional vector
/// @param	{vec}	extends		extends from center to each edge
function aabb(position=vec(), extends=vec()){
	return {
		position : position,
		extends : vec_abs(extends)
	}
}

function is_aabb(value){
	if (not is_struct(value))
		return false;
	
	if (struct_names_count(value) != 2)
		return false;
	
	if (not is_vec(value[$ "position"]))
		return false;
	
	if (not is_vec(value[$ "extends"]))
		return false;
	
	return true;
}

function aabb_duplicate(_aabb){
	return {
		position : vec_duplicate(_aabb.position),
		extends : vec_duplicate(_aabb.extends)
	}
}

/// @desc	Returns if the two AABB shapes overlap. Does NOT check for AABB
///			validity for speed reasons.
/// @param	{aabb}	aabb_a
/// @param	{aabb}	aabb_b
function aabb_intersects_aabb(aabb_a, aabb_b){
	static AXIS_ARRAY = [ // Axes to check; must be an overlap w/ all
			Node.AXIS_FORWARD,
			Node.AXIS_UP,
			Node.AXIS_RIGHT
		];
		
	/// @note	Done as a static as these arrays are surprisingly slow 
	///			to create.
	static EXTEND_A_ARRAY = [
		[0, 0],
		[0, 0],
		[0, 0]
	];
	static EXTEND_B_ARRAY = [
		[0, 0],
		[0, 0],
		[0, 0]
	];
	
	var position_a = aabb_a[$ "position"] ?? vec();
	var position_b = aabb_b[$ "position"] ?? vec();
	var extends_a = aabb_a[$ "extends"] ?? vec();
	var extends_b = aabb_b[$ "extends"] ?? vec();
	
	EXTEND_A_ARRAY[0][0] = position_a.x - extends_a.x; EXTEND_B_ARRAY[0][0] = position_b.x - extends_b.x;
	EXTEND_A_ARRAY[0][1] = position_a.x + extends_a.x; EXTEND_B_ARRAY[0][1] = position_b.x + extends_b.x;
	EXTEND_A_ARRAY[1][0] = position_a.y - extends_a.y; EXTEND_B_ARRAY[1][0] = position_b.y - extends_b.y;
	EXTEND_A_ARRAY[1][1] = position_a.y + extends_a.y; EXTEND_B_ARRAY[1][1] = position_b.y + extends_b.y;
	EXTEND_A_ARRAY[2][0] = position_a.z - extends_a.z; EXTEND_B_ARRAY[2][0] = position_b.z - extends_b.z;
	EXTEND_A_ARRAY[2][1] = position_a.z + extends_a.z; EXTEND_B_ARRAY[2][1] = position_b.z + extends_b.z;
	
	for (var i = 0; i < 3; ++i){
		var overlap = get_interval(EXTEND_A_ARRAY[i][0], EXTEND_A_ARRAY[i][1], EXTEND_B_ARRAY[i][0], EXTEND_B_ARRAY[i][1]);
		if (is_undefined(overlap)) // No overlap so no collision
			return false;
	}
	
	return true;
}

/// @desc	Given a vector, returns if the aabb contains it.
/// @param	{aabb}	aabb	AABB to check against
/// @param	{vec}	point	vector to check
function aabb_contains_point(aabb_a, point){
	var position = aabb_a[$ "position"] ?? vec();
	var extends = aabb_a[$ "extends"] ?? vec();
	
	if (abs(point.x - position.x) > extends.x)
		return false;
	
	if (abs(point.y - position.y) > extends.y)
		return false;
	
	if (abs(point.z - position.z) > extends.z)
		return false;
	
	return true;
}

/// @desc	Given a ray starting position and direction, returns the intersection
///			point or undefined.
/// @param	{vec}	position	position of the ray
/// @param	{vec}	direction	pointing direction of the ray
/// @param	{aabb}	aabb		aabb to check against
function ray_intersects_aabb(position, _direction, _aabb){
	if (aabb_contains_point(_aabb, position))
		return position;
	
	var position_origin = position;
	position = vec_sub_vec(position, _aabb.position);
		
	var ray_inv = vec_invert(_direction);
	ray_inv.x = (ray_inv.x >= infinity ? 10000000 : ray_inv.x);
	ray_inv.y = (ray_inv.y >= infinity ? 10000000 : ray_inv.y);
	ray_inv.z = (ray_inv.z >= infinity ? 10000000 : ray_inv.z);
	
	var t1 = (-_aabb.extends.x - position.x) * ray_inv.x;
	var t2 = (_aabb.extends.x - position.x) * ray_inv.x;
	var t3 = (-_aabb.extends.y - position.y) * ray_inv.y;
	var t4 = (_aabb.extends.y - position.y) * ray_inv.y;
	var t5 = (-_aabb.extends.z - position.z) * ray_inv.z;
	var t6 = (_aabb.extends.z - position.z) * ray_inv.z;
	
	var tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
	var tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));
	if (tmax < 0) // Pointing away from box
		return undefined;
		
	if (tmin > tmax)	// Doesn't intersect
		return undefined;
	
	return vec_add_vec(position_origin, vec_set_length(_direction, tmin));
}

function line_intersects_aabb(position, _direction, _length, _aabb){
	var intersection = ray_intersects_aabb(position, _direction, _aabb);
	if (is_undefined(intersection))
		return undefined;
	
	if (vec_magnitude(vec_sub_vec(position, intersection)) > _length)	
		return undefined;
	
	return intersection;
}

function sphere_intersects_aabb(position, radius, _aabb){
	var point_edge = aabb_clamp_vec(_aabb, position);
	var is_collision = false;
	var is_inside = false;
	if (vec_equals_vec(point_edge, position)){ // Center of sphere fell inside the bounding box
		is_collision = true;
		is_inside = true;
	}
	else // See if close enough for intersection
		is_collision = (vec_magnitude(vec_sub_vec(point_edge, position)) <= radius);
	
	if (not is_collision) // No collision; we're done
		return undefined;
	
	var push_vector;
	
	if (is_inside){ // If fully inside; just find the smallest axis-aligned push vector 
		var push_forward = vec((radius - abs(point_edge.x - _aabb.position.x)) * sign(point_edge.x - _aabb.position.x), 0, 0);
		var push_up = vec(0, (radius - abs(point_edge.y - _aabb.position.y)) * sign(point_edge.y - _aabb.position.y), 0);
		var push_right = vec(0, 0, (radius - abs(point_edge.z - _aabb.position.z)) * sign(point_edge.z - _aabb.position.z));
		push_vector = vec_min_magnitude(push_forward, push_up, push_right);
	}
	else{ // If not fully inside, push out from the closest point
		push_vector = vec_sub_vec(position, point_edge);
		push_vector = vec_mul_scalar(vec_normalize(push_vector), radius - vec_magnitude(push_vector));
	}
	
	return push_vector;
}

/// @desc	Returns the surface area of the specified aabb
function aabb_get_surface_area(_aabb){
	if (not is_aabb(_aabb)){
		Exception.throw_conditional("invalid type, expected [aabb]!");
		return 0;
	}
	
	var dx = _aabb.extends.x * 2;
	var dy = _aabb.extends.y * 2;
	var dz = _aabb.extends.z * 2;
	var sa = 0;
	
	sa += dx * dy; // +Z
	sa += dz * dy; // +X
	sa += dx * dz; // +Y
	
	return sa * 2.0;	// *2 to account for both sides
}

/// @desc	Takes two AABB structures and returns a new one that contains them both.
function aabb_add_aabb(aabb_a, aabb_b){
	var min_vec = vec_min(vec_sub_vec(aabb_a.position, aabb_a.extends), vec_sub_vec(aabb_b.position, aabb_b.extends));
	var max_vec = vec_max(vec_add_vec(aabb_a.position, aabb_a.extends), vec_add_vec(aabb_b.position, aabb_b.extends));
	var origin = vec_lerp(min_vec, max_vec, 0.5);
	var extends = vec_mul_scalar(vec_sub_vec(max_vec, min_vec), 0.5);
	return aabb(origin, extends);
}

/// @desc	Returns the specified point clamped inside of the aabb.
/// @param	{aabb}	aabb		aabb to clamp to
/// @param	{vec}	vec			vector to clamp
function aabb_clamp_vec(_aabb, _vec){
	return vec_clamp(_vec, vec_sub_vec(_aabb.position, _aabb.extends), vec_add_vec(_aabb.position, _aabb.extends));
}