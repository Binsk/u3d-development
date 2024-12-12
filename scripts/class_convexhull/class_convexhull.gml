/// @about
/// A convex hull is an arbitrary 3D shape with the one requirement of NOT having
///	any cavities in its shape. Calculating collisions with convex hulls gets exponentially
/// more expensive the more points they have, so their shape definitions should be kept
/// as simple as possible.
///
/// Unlike base shapes, convex hulls must be defined after they are created.

/// @todo	Implement morphing point, edge, axes to match attached body. This WILL
///			be very slow but may be needed for static object placement in-game.

/// https://gamedev.stackexchange.com/questions/43855/how-do-i-get-the-axes-for-sat-collision-detection/43856#43856
function ConvexHull(point_count=0, edge_count=0, axis_count=0) : AABB() constructor {
	#region PROPERTIES
	point_array = array_create(point_count, vec());	// Array of all vertex points for the shape
	edge_array = array_create(edge_count, vec());	// Array of all edge directions for the shape
	axis_array = array_create(axis_count, vec());	// Array of all normalized axes (face normals) for the shape
	point_index = 0; // Currently defining point
	edge_index = 0;
	axis_index = 0;	// Currently defining axis
	needs_reprocess = false;	//	 Whether or not the AABB bounds need re-processing
	#endregion
	
	#region STATIC METHODS
	#endregion
	
	#region METHODS
	/// @desc	Attempts to add a point to the shape; returns if successful
	function add_point(point){
		if (not is_vec(point)){
			Exception.throw_conditional("invalid type, expected [vec]!");
			return false;
		}
		
		for (var i = 0; i < point_index; ++i){
			if (vec_equals_vec(point_array[i], point))
				return false;
		}
		
		point_array[point_index++] = point;
		needs_reprocess = true;
		return true;
	}
	
	/// @desc	Attempts to add an edge to the shape; returns if successful.
	function add_edge(edge){
		if (not is_vec(edge)){
			Exception.throw_conditional("invalid type, expected [vec]!");
			return false;
		}
		
		edge = vec_normalize(edge);
		// Loop through existing axes and check for duplicates:
		for (var i = 0; i < edge_index; ++i){
			var dot = vec_dot(edge, edge_array[i]);
			if (abs(dot) >= 1)	// There is a similar axis; ignore
				return false;
		}
		
		edge_array[edge_index++] = edge;
		needs_reprocess = true;
		return true;
	}
	
	/// @desc	Attempts to add an axis to the shape; returns if successful.
	function add_axis(axis){
		if (not is_vec(axis)){
			Exception.throw_conditional("invalid type, expected [vec]!");
			return false;
		}
		
		axis = vec_normalize(axis);
		// Loop through existing axes and check for duplicates:
		for (var i = 0; i < axis_index; ++i){
			var dot = vec_dot(axis, axis_array[i]);
			if (abs(dot) >= 1)	// There is a similar axis; ignore
				return false;
		}
		
		axis_array[axis_index++] = axis;
		needs_reprocess = true;
		return true;
	}
	
	/// @desc	Given a primitive, reads the vertices and adds them + normals
	///			to the shape. The primitive MUST be convex otherwise collisions
	///			will not work correctly.
	function add_primitive(primitive){
		if (primitive.get_is_frozen())
			throw new Exception("failed to generate ConvexHull, primitive is frozen!");
		
		needs_reprocess = true;
		var format = primitive.vformat;
		var vertex_bytes = format.get_byte_count();
		var vertex_count = primitive.get_triangle_count() * 3;
		var buffer = buffer_create_from_vertex_buffer(primitive.vbuffer, buffer_fixed, 1);
		var triangle = [0, 0, 0];
		
		/// Note:	vertex directions don't matter until the MTV is calculated, and
		///			at that point we can swap direction as needed.
		for (var i = 0; i < vertex_count; ++i){
			var imod = (i % 3);
			buffer_seek(buffer, buffer_seek_start, vertex_bytes * i);
			var position = buffer_read_series(buffer, buffer_f32, 3);
			triangle[imod] = vec(position[0], position[1], position[2]);
			
			// Process point:
			add_point(triangle[imod]);
			
			if (imod != 2)
				continue;
			
			// Process edges
			var e1 = vec_sub_vec(triangle[1], triangle[0]);
			var e2 = vec_sub_vec(triangle[2], triangle[1]);
			var e3 = vec_sub_vec(triangle[0], triangle[2]);
			add_edge(e1);
			add_edge(e2);
			add_edge(e3);
			
			// Process face:
			add_axis(vec_cross(e1, e2));
		}
		
		buffer_delete(buffer);
	}
	
	/// @desc	Reprocesses the AABB bounds; note that this may shift the 'center of mass'
	/// 		and thus make an offset occur with connected bodies. It is best to NOT modify
	///			a shape after it has been attached to a body.
	function reprocess_bounds(){
		if (not needs_reprocess)	
			return;
		
		needs_reprocess = false;
		var vector_min = vec(infinity, infinity, infinity);
		var vector_max = vec(-infinity, -infinity, -infinity);
		for (var i = 0; i < point_index; ++i){
			vector_min = vec_min(vector_min, point_array[i]);
			vector_max = vec_max(vector_max, point_array[i]);
		}
		
		extends = vec_mul_scalar(vec_sub_vec(vector_max, vector_min), 0.5);
	}
	
	super.register("transform");
	function transform(node){
		reprocess_bounds();
		
		if (not super.execute("transform", [node]))
			return false;
		
		return true;
	}

	#endregion
}