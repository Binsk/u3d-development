/// @about
/// A capsule is a 'pill' shape that is effectively a cylinder with two half-
/// spheres on each end. Capsules are defined with the height along the y-axis
/// from sphere end to sphere end with the specified cylindrical radius.
/// Capsules are aligned at their center.
function Capsule(height, radius) : AABB(vec(radius, height * 0.5, radius)) constructor {
	#region STATIC METHODS
	#endregion
	
	#region METHODS
	function render_debug(node){
		super.execute("render_debug", [node]);
		var r_color = [color_get_red(draw_get_color()) / 255, color_get_green(draw_get_color()) / 255, color_get_blue(draw_get_color()) / 255];
		transform(node);
		
		var render_extends = node.get_data(["collision", "aabb_extends"], self.extends);
		var vformat = VertexFormat.get_format_instance([VERTEX_DATA.position]).get_format();
		var vbuffer = vertex_create_buffer();
		
		var y_offset = render_extends.y - render_extends.x;
		
		vertex_begin(vbuffer, vformat);
		// Edges:
		vertex_position_3d(vbuffer, render_extends.x, y_offset, 0);
		vertex_position_3d(vbuffer, render_extends.x, -y_offset, 0);
		vertex_position_3d(vbuffer, -render_extends.x, y_offset, 0);
		vertex_position_3d(vbuffer, -render_extends.x, -y_offset, 0);
		vertex_position_3d(vbuffer, 0, y_offset, render_extends.x);
		vertex_position_3d(vbuffer, 0, -y_offset, render_extends.x);
		vertex_position_3d(vbuffer, 0, y_offset, -render_extends.x);
		vertex_position_3d(vbuffer, 0, -y_offset, -render_extends.x);
		
		// Rings:
		var d = (pi * 2.0) / 32;
		for (var i = 0; i < 16; ++i){
			var t1 = d * i;
			var t2 = d * (i + 1);
			var ct1 = cos(t1);
			var ct2 = cos(t2);
			var st1 = sin(t1);
			var st2 = sin(t2);
			vertex_position_3d(vbuffer, ct1 * render_extends.x, y_offset, -st1 * render_extends.x);
			vertex_position_3d(vbuffer, ct2 * render_extends.x, y_offset, -st2 * render_extends.x);
			vertex_position_3d(vbuffer, ct1 * render_extends.x, -y_offset, -st1 * render_extends.x);
			vertex_position_3d(vbuffer, ct2 * render_extends.x, -y_offset, -st2 * render_extends.x);
			
			vertex_position_3d(vbuffer, -ct1 * render_extends.x, y_offset, st1 * render_extends.x);
			vertex_position_3d(vbuffer, -ct2 * render_extends.x, y_offset, st2 * render_extends.x);
			vertex_position_3d(vbuffer, -ct1 * render_extends.x, -y_offset, st1 * render_extends.x);
			vertex_position_3d(vbuffer, -ct2 * render_extends.x, -y_offset, st2 * render_extends.x);
		}
		
		// Caps:
		for (var i = 0; i < 16; ++i){
			var t1 = d * i;
			var t2 = d * (i + 1);
			var ct1 = cos(t1);
			var ct2 = cos(t2);
			var st1 = sin(t1);
			var st2 = sin(t2);
			vertex_position_3d(vbuffer, ct1 * render_extends.x, y_offset + st1 * render_extends.x, 0);
			vertex_position_3d(vbuffer, ct2 * render_extends.x, y_offset + st2 * render_extends.x, 0);
			vertex_position_3d(vbuffer, 0, y_offset + st1 * render_extends.x, ct1 * render_extends.x);
			vertex_position_3d(vbuffer, 0, y_offset + st2 * render_extends.x, ct2 * render_extends.x);
			
			vertex_position_3d(vbuffer, ct1 * render_extends.x, -y_offset - st1 * render_extends.x, 0);
			vertex_position_3d(vbuffer, ct2 * render_extends.x, -y_offset - st2 * render_extends.x, 0);
			vertex_position_3d(vbuffer, 0, -y_offset - st1 * render_extends.x, ct1 * render_extends.x);
			vertex_position_3d(vbuffer, 0, -y_offset - st2 * render_extends.x, ct2 * render_extends.x);
		}
		
		vertex_end(vbuffer);
		
		uniform_set("u_vColor", shader_set_uniform_f, r_color);
		var matrix_model = matrix_get(matrix_world);
		
		matrix_set(matrix_world, matrix_build_translation(vec_add_vec(node.position, node.get_data(["collision", "offset"], vec()))));
		vertex_submit(vbuffer, pr_linelist, -1);
		matrix_set(matrix_world, matrix_model);
		
		vertex_delete_buffer(vbuffer);
	}
	#endregion
}