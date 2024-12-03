  /// @about
/// An AABB is a collision box that is always aligned to the global axes and is exceptionally
/// fast at detecting collisions. This shape is commonly used as a first check before proceeding
/// to more complicated shapes.
///
// If an AABB is NOT static then it will morph its size / shape as the node rotates and scales.

/// @param	{vec}	extends		the length from origin the box stretches out it each direction
function AABB(extends=vec()) : Collidable() constructor {
	#region PROPERTIES
	self.extends = vec_abs(extends);
	#endregion
	
	#region STATIC METHODS
	/// @desc	Returns the collision info between the aabb and the ray.
	/// @param	{AABB}	aabb
	/// @param	{Ray}	ray
	/// @param	{Node}	node_a		node defining spatial information for aabb
	/// @param	{Node}	node_b		node defining spatial information for ray
	static collide_ray = function(aabb_a, ray_b, node_a, node_b){
		return Ray.collide_aabb(ray_b, aabb_a, node_b, node_a);
	}
	
	/// @desc	Returns the collision info between the two aabb shapes.
	/// @param	{AABB}	aabb_a
	/// @param	{AABB}	aabb_b
	/// @param	{Node}	node_a		node defining spatial information for aabb
	/// @param	{Node}	node_b		node defining spatial information for ray
	static collide_aabb = function(aabb_a, aabb_b, node_a, node_b){
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
		
		var position_a = vec_add_vec(node_a.position, node_a.get_data("collision.offset", vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data("collision.offset", vec()));
		var extends_a = node_a.get_data(["collision", "extends"], aabb_a.extends);
		var extends_b = node_b.get_data(["collision", "extends"], aabb_b.extends);
		
		var axis_min = -1;	// Axis w/ minimum push
		var length_min = infinity;	// Length of shortest push
		var push_array = [undefined, undefined, undefined];
		
		EXTEND_A_ARRAY[0][0] = position_a.x - extends_a.x; EXTEND_B_ARRAY[0][0] = position_b.x - extends_b.x;
		EXTEND_A_ARRAY[0][1] = position_a.x + extends_a.x; EXTEND_B_ARRAY[0][1] = position_b.x + extends_b.x;
		EXTEND_A_ARRAY[1][0] = position_a.y - extends_a.y; EXTEND_B_ARRAY[1][0] = position_b.y - extends_b.y;
		EXTEND_A_ARRAY[1][1] = position_a.y + extends_a.y; EXTEND_B_ARRAY[1][1] = position_b.y + extends_b.y;
		EXTEND_A_ARRAY[2][0] = position_a.z - extends_a.z; EXTEND_B_ARRAY[2][0] = position_b.z - extends_b.z;
		EXTEND_A_ARRAY[2][1] = position_a.z + extends_a.z; EXTEND_B_ARRAY[2][1] = position_b.z + extends_b.z;
		
		for (var i = 0; i < 3; ++i){
			var overlap = get_interval(EXTEND_A_ARRAY[i][0], EXTEND_A_ARRAY[i][1], EXTEND_B_ARRAY[i][0], EXTEND_B_ARRAY[i][1]);
			if (is_undefined(overlap)) // No overlap so no collision:
				return undefined;
			
			push_array[i] = vec_set_length(AXIS_ARRAY[i], overlap);
			
			if (abs(overlap) >= abs(length_min))	// Overlap is larger so discard push
				continue;
			
			length_min = overlap;
			axis_min = i
		}
		
		// We had a collision, create the data:
		var data = new CollidableDataAABB(node_a, node_b, AABB);
		data.data = {
			push_vector : push_array[axis_min],	// Shortest push vector
			push_forward : push_array[0],		// X-axis push vector
			push_up : push_array[1],			// Y-axis push vector
			push_right : push_array[2]			// Z-axis push vector
		}
		
		return data;
	}
	#endregion
	
	#region METHODS
	super.register("transform");
	function transform(node){
		if (not super.execute("transform", [node]))
			return false;
		
		// If static, we don't adjust:
		if (node.get_data("collision.static", false)){
			node.set_data(["collision", "extends"], extends);
			return true;
		}
			
		// Calculate extends w/ node rotation:
		if (quat_is_identity(node.rotation)) // If no rotation short-cut the transforms
			node.set_data(["collision", "extends"], vec_mul_vec(node.scale, extends));
		else {
			var corner_1 = vec_abs(quat_rotate_vec(node.rotation, vec_mul_vec(node.scale, extends)));
			var corner_2 = vec_abs(quat_rotate_vec(node.rotation, vec_mul_vec(node.scale, vec(extends.x, -extends.y, -extends.z))));
			var extends_c = vec(
				max(corner_1.x, corner_2.x),
				max(corner_1.y, corner_2.y),
				max(corner_1.z, corner_2.z),
			);
			node.set_data(["collision", "extends"], extends_c);
		}
		
		return true;
	}
	
	super.register("render_debug");
	function render_debug(node){
		super.execute("render_debug", [node]);
		var r_color = [color_get_red(draw_get_color()) / 255, color_get_green(draw_get_color()) / 255, color_get_blue(draw_get_color()) / 255];
		transform(node);
		
		var render_extends = node.get_data(["collision", "extends"], self.extends);
		var vformat = VertexFormat.get_format_instance([VERTEX_DATA.position]).get_format();
		var vbuffer = vertex_create_buffer();
		
		vertex_begin(vbuffer, vformat);
			// Top
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, -render_extends.z);
		
			// Bottom
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, -render_extends.z);
		
			// Edges:
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, -render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, -render_extends.z);
		
		vertex_position_3d(vbuffer, render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_position_3d(vbuffer, -render_extends.x, render_extends.y, render_extends.z);
		vertex_position_3d(vbuffer, -render_extends.x, -render_extends.y, render_extends.z);
		
		vertex_end(vbuffer);
		
		uniform_set("u_vColor", shader_set_uniform_f, r_color);
		var matrix_model = matrix_get(matrix_world);
		
		matrix_set(matrix_world, matrix_build_translation(vec_add_vec(node.position, node.get_data("collision.offset", vec()))));
		vertex_submit(vbuffer, pr_linelist, -1);
		matrix_set(matrix_world, matrix_model);
		
		vertex_delete_buffer(vbuffer);
	}
	#endregion
}

function CollidableDataAABB(body_a, body_b, type_b=Collidable) : CollidableData(AABB, type_b) constructor {
	#region PROPERTIES
	self.body_a = body_a;
	self.body_b = body_b;
	#endregion
	
	#region METHODS
	/// @desc	Returns the push vector required to push body_b out
	///			of body_a on the shortest side.
	function get_push_vector(){
		return data.push_vector;
	}
	
	/// @desc	Returns the push vector require to push body_b out
	///			of body_a on the local forward axis.
	/// @note	Vector may be negative.
	function get_push_x(){
		return data.push_forward;
	}
	
	/// @desc	Returns the push vector require to push body_b out
	///			of body_a on the local up axis.
	/// @note	Vector may be negative.
	function get_push_y(){
		return data.push_up;
	}
	
	/// @desc	Returns the push vector require to push body_b out
	///			of body_a on the local right axis.
	/// @note	Vector may be negative.
	function get_push_z(){
		return data.push_right;
	}
	#endregion
	
}