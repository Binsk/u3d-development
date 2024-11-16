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
			// var axis_x = vec_abs(quat_rotate_vec(node.rotation, vec(node.scale.x * extends.x, 0, 0)));
			// var axis_y = vec_abs(quat_rotate_vec(node.rotation, vec(0, node.scale.y * extends.y, 0)));
			// var axis_z = vec_abs(quat_rotate_vec(node.rotation, vec(0, 0, node.scale.z * extends.z)));
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
	
	function render_debug(node){
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
		
		uniform_set("u_vColor", shader_set_uniform_f, [0, 1, 0]);
		var matrix_model = matrix_get(matrix_world);
		matrix_set(matrix_world, matrix_build_translation(vec_add_vec(node.position, node.get_data(["collision", "offset"], vec()))));
		vertex_submit(vbuffer, pr_linelist, -1);
		matrix_set(matrix_world, matrix_model);
		vertex_delete_buffer(vbuffer);
	}
	#endregion
}