/// @about
/// A capsule is a 'pill' shape that is effectively a cylinder with two half-
/// spheres on each end. Capsules are defined with the height along the y-axis
/// from sphere end to sphere end with the specified cylindrical radius.
/// Capsules are aligned at their center.

/// @todo	Add rotation to capsule calculations; ALL capsules ignore rotation ATM.
function Capsule(height, radius) : AABB(vec(radius, height * 0.5, radius)) constructor {
	/// @note	Height / Radius is stored in the extends where:
	///			extends.y == height * 0.5
	///			extends.x == radius
	#region STATIC METHODS
	static collide_capsule = function(capsule_a, capsule_b, node_a, node_b){
		var position_a = vec_add_vec(node_a.position, node_a.get_data(["collision", "offset"], vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data(["collision", "offset"], vec()));
		var extends_a = node_a.get_data(["collision", "aabb_extends"], capsule_a.extends);
		var extends_b = node_b.get_data(["collision", "aabb_extends"], capsule_b.extends);
		var position_c = vec_add_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));	// Top and bottom accounting for radius
		var position_bottom = vec_sub_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));
		position_c.y = clamp(position_b.y, position_bottom.y, position_c.y); // Collision point we should use
		var position_d = vec_add_vec(position_b, vec(0, extends_b.y - extends_b.x, 0));	// Top and bottom accounting for radius
		position_bottom = vec_sub_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));
		position_d.y = clamp(position_a.y, position_bottom.y, position_d.y); // Collision point we should use
		
		var radius_a = extends_a.x;
		var radius_b = vec_min_component(extends_b);
		
		var distance = vec_magnitude(vec_sub_vec(position_c, position_d));
		if (distance > radius_a + radius_b)	// No collision
			return undefined;
		
		var radius_combined = radius_a + radius_b;
		var push_vector = vec_normalize(vec_sub_vec(position_c, position_d));
		push_vector = vec_mul_scalar(push_vector, (radius_a + radius_b) - distance);
		var data = new CollidableDataSpatial(node_a, node_b, Capsule, Sphere);
		data.data.push_vector = push_vector;
		data.data.push_forward = vec((radius_combined - abs(position_c.x - position_d.x)) * sign(position_c.x - position_d.x), 0, 0);
		data.data.push_up = vec((radius_combined - abs(position_c.y - position_d.y)) * sign(position_c.y - position_d.y), 0, 0);
		data.data.push_right = vec((radius_combined - abs(position_c.z - position_d.z)) * sign(position_c.z - position_d.z), 0, 0);
		return data;
	}
	
	static collide_sphere = function(capsule_a, sphere_b, node_a, node_b){
		var position_a = vec_add_vec(node_a.position, node_a.get_data(["collision", "offset"], vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data(["collision", "offset"], vec()));
		var extends_a = node_a.get_data(["collision", "aabb_extends"], capsule_a.extends);
		var extends_b = node_b.get_data(["collision", "aabb_extends"], sphere_b.extends);
		var position_c = vec_add_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));	// Top and bottom accounting for radius
		var position_bottom = vec_sub_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));
		position_c.y = clamp(position_b.y, position_bottom.y, position_c.y); // Collision point we should use
		
		var radius_a = extends_a.x;
		var radius_b = vec_min_component(extends_b);
		
		var distance = vec_magnitude(vec_sub_vec(position_c, position_b));
		if (distance > radius_a + radius_b)	// No collision
			return undefined;
		
		var radius_combined = radius_a + radius_b;
		var push_vector = vec_normalize(vec_sub_vec(position_c, position_b));
		push_vector = vec_mul_scalar(push_vector, (radius_a + radius_b) - distance);
		var data = new CollidableDataSpatial(node_a, node_b, Capsule, Sphere);
		data.data.push_vector = push_vector;
		data.data.push_forward = vec((radius_combined - abs(position_c.x - position_b.x)) * sign(position_c.x - position_b.x), 0, 0);
		data.data.push_up = vec((radius_combined - abs(position_c.y - position_b.y)) * sign(position_c.y - position_b.y), 0, 0);
		data.data.push_right = vec((radius_combined - abs(position_c.z - position_b.z)) * sign(position_c.z - position_b.z), 0, 0);
		return data;
	}
	
	static collide_aabb = function(capsule_a, aabb_b, node_a, node_b){
		var position_a = vec_add_vec(node_a.position, node_a.get_data(["collision", "offset"], vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data(["collision", "offset"], vec()));
		var extends_a = node_a.get_data(["collision", "aabb_extends"], capsule_a.extends);
		var extends_b = node_b.get_data(["collision", "aabb_extends"], aabb_b.extends);
		var position_top = vec_add_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));	// Top and bottom accounting for radius
		var position_bottom = vec_sub_vec(position_a, vec(0, extends_a.y - extends_a.x, 0));
		var push_vector = undefined;

	/// @stub	At the moment we don't use rotations so we can make some assumptions.
	///			Will need to account for capsule rotation down the line.
		// Line collision check w/ expanded AABB
		var _aabb = aabb(position_b, vec_add_vec(extends_b, vec(extends_a.x, 0, extends_a.x)));	// Extend by radius
		var position_top_clamped = aabb_clamp_vec(_aabb, position_top);
		var position_bottom_clamped = aabb_clamp_vec(_aabb, position_bottom);
		var intersection = undefined;
			// First detect if ends are inside the box; if so prioritize pushing from that point:
		if (vec_equals_vec(position_bottom_clamped, position_bottom))	// Bottom is inside a box
			intersection = position_bottom;
		else if (vec_equals_vec(position_top_clamped, position_top))	// Top is inside a box
			intersection = position_top;
		
			// Ends are not inside so shoot some rays to determine the best point to push
			// the body from:
		if (is_undefined(intersection)){
			var int_1 = ray_intersects_aabb(vec_add_vec(position_top, vec(0, extends_a.x, 0)), vec(0, -1, 0), _aabb);
			if (not is_undefined(int_1)){ /// @note	Second ray generally not needed but helps with some edge-cases
				var int_2 = ray_intersects_aabb(vec_add_vec(position_bottom, vec(0, -extends_a.x, 0)), vec(0, 1, 0), _aabb);
				if (not is_undefined(int_2))
					intersection = vec_lerp(int_1, int_2, 0.5);
				else // Shouldn't be possible
					intersection = int_1;
			}
		}
		
		if (is_undefined(intersection))	// No collision
			return undefined;
		
		// Make sure our collision point clamps in to the end-point sphere centers:
		intersection.y = clamp(intersection.y, position_bottom.y, position_top.y); // Point on the line to check
		// Perform a spherical check:
		push_vector = sphere_intersects_aabb(intersection, extends_a.x, aabb(position_b, extends_b));
		
		/// @note	Broken edge-case if the capsule is 'cut in half' w/ a very wide/long shape on x/z
		
		if (is_undefined(push_vector))
			return undefined;
		
		var data = new CollidableDataSpatial(node_a, node_b, Capsule, AABB);
/// @stub	Calculate proper push_* vectors for each axis
		data.data = {
			push_forward : undefined,
			push_up : undefined,
			push_right : undefined,
			push_vector : push_vector
		}
		
		return data;
	}
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