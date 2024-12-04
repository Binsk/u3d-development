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