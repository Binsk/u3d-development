/// @about
/// Defines an inifinite plane in 3D space where the normal specified is the 
/// facing direction of the plane.

/// @param	{vec}	normal		face normal defining plane orientation
function Plane(normal=vec(0, 1, 0)) : Collidable() constructor {
	#region PROPERTIES
	self.normal = vec_normalize(normal);
	#endregion
	
	#region METHODS
	
	/// @desc	Returns the collision info between the plane and a ray.
	/// @param	{Plane}	plane
	/// @param	{Ray}	ray
	/// @param	{Node}	node_a		node defining spatial information for plane
	/// @param	{Node}	node_b		node defining spatial information for ray
	static collide_ray = function(plane_a, ray_b, node_a, node_b){
		return Ray.collide_plane(ray_b, plane_a, node_b, node_a);
	}
	
	/// @desc	Returns the collision info between the plane and another plane
	/// @param	{Plane}	plane_a
	/// @param	{Plane}	plane_b
	/// @param	{Node}	node_a		node defining spatial information for plane_a
	/// @param	{Node}	node_b		node defining spatial information for plane_b
	static collide_plane = function(plane_a, plane_b, node_a, node_b){
/// @stub	Implement; namely the infinite line of intersection
		return undefined;
	}
	
	function transform(node){
		if (not super.execute("transform", [node]))
			return false;
			
		// Calculate rotation relative to the node
		if (node.get_data("collision.static", false))
			node.set_data(["collision", "orientation"], self.normal);
		else
			node.set_data(["collision", "orientation"], vec_normalize(matrix_multiply_vec(node.get_model_matrix(), self.normal)));
		return true;
	}
	
	super.register("render_debug");
	function render_debug(node){
		super.execute("render_debug", [node]);
		var r_color = [color_get_red(draw_get_color()) / 255, color_get_green(draw_get_color()) / 255, color_get_blue(draw_get_color()) / 255];
		transform(node);
		
		var normal = vec_normalize(node.get_data(["collision", "orientation"], self.normal));
		var tangent = vec_normalize(vec_get_perpendicular(normal));
		var bitangent = vec_normalize(vec_cross(normal, tangent));
		tangent = vec_normalize(vec_cross(bitangent, normal));
		var length = (Eye.ACTIVE_INSTANCE.zfar - Eye.ACTIVE_INSTANCE.znear) * 0.01; // Arbitrary size; we decided on 1% of viewing distance-
		length = clamp(length, 1.0, 24.0);	// Limit in case someone just has weird z-values
		
		normal = vec_set_length(normal, length);
		tangent = vec_set_length(tangent, length);
		bitangent = vec_set_length(bitangent, length);
		
		var vformat = VertexFormat.get_format_instance([VERTEX_DATA.position]).get_format();
		var vbuffer = vertex_create_buffer();
		vertex_begin(vbuffer, vformat);
		
		// Axes:
		vertex_position_3d(vbuffer, 0, 0, 0);
		vertex_position_3d(vbuffer, normal.x, normal.y, normal.z);
		vertex_position_3d(vbuffer, 0, 0, 0);
		vertex_position_3d(vbuffer, tangent.x, tangent.y, tangent.z);
		vertex_position_3d(vbuffer, 0, 0, 0);
		vertex_position_3d(vbuffer, bitangent.x, bitangent.y, bitangent.z);
		
		// Rectangle:
		length *= 3;
		var p1 = vec_set_length(vec_add_vec(vec_reverse(tangent), vec_reverse(bitangent)), length);
		var p2 = vec_set_length(vec_add_vec(tangent, vec_reverse(bitangent)), length);
		var p3 = vec_set_length(vec_add_vec(tangent, bitangent), length);
		var p4 = vec_set_length(vec_add_vec(vec_reverse(tangent), bitangent), length);
		
		vertex_position_3d(vbuffer, p1.x, p1.y, p1.z);
		vertex_position_3d(vbuffer, p2.x, p2.y, p2.z);
		
		vertex_position_3d(vbuffer, p2.x, p2.y, p2.z);
		vertex_position_3d(vbuffer, p3.x, p3.y, p3.z);
		
		vertex_position_3d(vbuffer, p3.x, p3.y, p3.z);
		vertex_position_3d(vbuffer, p4.x, p4.y, p4.z);
		
		vertex_position_3d(vbuffer, p4.x, p4.y, p4.z);
		vertex_position_3d(vbuffer, p1.x, p1.y, p1.z);
		
		vertex_end(vbuffer);
		
		uniform_set("u_vColor", shader_set_uniform_f, r_color);
		var matrix_model = matrix_get(matrix_world);
		matrix_set(matrix_world, matrix_build_translation(vec_add_vec(node.position, node.get_data("collision.offset", vec()))));
		vertex_submit(vbuffer, pr_linelist, -1);
		vertex_delete_buffer(vbuffer);
	}
	#endregion
}