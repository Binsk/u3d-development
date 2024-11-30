/// @about
/// A CameraView is a camera with 1 eye that renders a scene and automatically 
/// displays it onto the screen. This is the most commonly used camera. Buffer size
/// will be auto-calculated based on obj_render_controller's render mode and the anchor
/// will specify where on the screen it will render.
///
/// znear, zfar, and fov is controlled by the Eye attached to this camera. You can grab
/// the eye instance with get_eye(). By default the eye is perspective.
/// @param	{Anchor2D} anchor	the anchor used to specify where in the window the camera should render
function CameraView(anchor=new Anchor2D()) : Camera() constructor {
	#region PROPERTIES
	self.anchor = anchor;
	supersample_multiplier = 1.0;
	render_width = 1;	// Size of the canvas we render out on (not our actual render size)
	render_height = 1;
	render_tonemap = CAMERA_TONEMAP.linear;
	eye_id = new EyePerspective(self, 0.01, 1024, 45);
	
	#region SHADER UNIFORMS
	uniform_sampler_texture = -1;
	#endregion
	
	#endregion
	
	#region METHODS
	/// @desc	How much to multiply the size of the render buffer by.
	function set_supersample_multiplier(multiplier=1.0){
		supersample_multiplier = max(0.01, multiplier);
	}
	
	/// @desc	Assigns a new eye to this camera. The eye MUST have bene created
	///			with this camera set as its parent!
	function set_eye(eye){
		if (not is_instanceof(eye, Eye)){
			Exception.throw_conditional("invalid type, expected [Eye]!");
			return;
		}
		
		if (not U3DObject.are_equal(eye.camera_id, self)){
			Exception.throw_conditional("cannot attach eye, invalid camera id!");
			return;
		}
		
		replace_child_ref(eye, eye_id);
		eye_id = eye; 
	}
	
	/// @desc	A function specific to this camera type; returns the eye attached
	///			to this class.
	function get_eye(){
		return get_eye_array()[0];
	}
	
	function get_eye_array(){
		return [eye_id];
	}
	
	function update_render_size(){
		var rwidth = 1;
		var rheight = 1;
		with (obj_render_controller){
			if (render_mode == RENDER_MODE.draw){
				if (not surface_exists(application_surface))
					return;
					
				rwidth = surface_get_width(application_surface);
				rheight = surface_get_height(application_surface);
			}
			else {
				rwidth = display_get_gui_width();
				rheight = display_get_gui_height();
			}
		}
		
		render_width = rwidth;
		render_height = rheight;
		
		rwidth = ceil(supersample_multiplier * rwidth);
		rheight = ceil(supersample_multiplier * rheight);
		
		var ndx = anchor.get_dx(rwidth);
		var ndy = anchor.get_dy(rheight);
		if ((buffer_width ?? 1 != ndx) or (buffer_height ?? 1) != ndy){
			eye_id.matrix_projection = undefined;
			eye_id.matrix_inv_projection = undefined;
		}
		
		buffer_width = ndx;
		buffer_height = ndy;
	}
	
	function render_out(){
		if (render_stages <= 0)
			return;
		
		var rw = render_width;
		var rh = render_height;
		
		var tonemap = render_tonemap;
		var exposure = exposure_level;
		var gamma = gamma_correction;
		
		if (debug_flags & ~3){ // If overriding w/ debugging, remove tonemapping
			tonemap = CAMERA_TONEMAP.linear;
			exposure = 1.0;
			gamma = false;
		}
		
		gpu_set_blendmode(bm_normal);
		shader_set(shd_tonemap);
		sampler_set("u_sTexture", gbuffer.textures[$ CAMERA_GBUFFER.final]);
		uniform_set("u_iTonemap", shader_set_uniform_i, tonemap);
		uniform_set("u_fExposure", shader_set_uniform_f, exposure);
		uniform_set("u_fWhite", shader_set_uniform_f, white_level);
		uniform_set("u_iGamma", shader_set_uniform_i, gamma);
		
		var u1 = 0, 
		v1 = 0, 
		u2 = 1, 
		v2 = 1;
		
		if (U3D.OS.is_browser) {
			/// @note	Browsers are forced to use 2^n dimension surfaces so we render that size
			///			but crop it for the render size. Not a perfect solution but gets the job done.
			/// @note2	Support for odd-dimensions IS THERE for browsers, but we get lots of surface failures
			///			if we don't use 2^n.
			var r1 = render_width / render_height;	// Aspect ratio 1
			var r2 = buffer_width / buffer_height;	// Aspect ratio 2
			if (r1 < r2){
				var sc = buffer_height / render_height;
				var sw = render_width * sc;
				u1 = (buffer_width - sw) / buffer_width * 0.5;
				u2 = 1.0 - u1;
			}
			else {
				var sc = buffer_width / render_width;
				var sh = render_height * sc;
				
				v1 = (buffer_height - sh) / buffer_height * 0.5;
				v2 = 1.0 - v1;
			}
		}
		
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(anchor.get_x(rw), anchor.get_y(rh), u2, v1);
		draw_vertex_texture(anchor.get_x(rw) + anchor.get_dx(rw), anchor.get_y(rh), u1, v1);
		draw_vertex_texture(anchor.get_x(rw), anchor.get_y(rh) + anchor.get_dx(rh), u2, v2);
		draw_vertex_texture(anchor.get_x(rw) + anchor.get_dx(rw), anchor.get_y(rh) + anchor.get_dy(rh), u1, v2);
		draw_primitive_end(); 

		shader_reset();
	}
	
	/// @desc	Given 2D point on the canvas, projects the location into 3D space and
	///			updates the provided ray to contain projection direction. Origin point
	///			can be assumed to be the camera's position.
	/// @warning	This does NOT trigger collision system updates! You will need to clear the
	///				collision data for the attached body and also manually queue a body update in
	///				the collision system if the body doesn't move on its own!
	/// @param	{real}	px	relative x-coordinate on the camera's canvas w/o supersample modifications
	/// @param	{real}	py	relative y-coordinate on the camera's canvas w/o supersample modifications
	/// @param	{Ray}	ray	collidable ray to update w/ the mouse projection
	function calculate_world_ray(px, py, ray){
		if (not is_instanceof(ray, Ray)){
			Exception.throw_conditional("invalid type, expected [Ray]!");
			return;
		}
		
		px *= supersample_multiplier;
		py *= supersample_multiplier;
		
		if (px < 0 or py < 0)
			return;
		if (px >= render_width or py >= render_height)
			return;
			
		// Convert to screen space [-1..1]:
			/// @note	We invert the axes due to the rendering canvas being flipped
		px = -((px / render_width) * 2.0 - 1.0);
		py = -((1.0 - py / render_height) * 2.0 - 1.0);
		if (get_is_directx_pipeline())
			py = -py;

		if (U3D.OS.is_browser) {
			/// @note	Because browsers crop/scale rendering output due to the 2^n requirement
			///			we need to compensate for it here to make sure the ray points correctly.
			var r1 = render_width / render_height;	// Aspect ratio 1
			var r2 = buffer_width / buffer_height;	// Aspect ratio 2
			if (r1 < r2){
				var sc = buffer_height / render_height;
				var sw = render_width * sc;
				px *= 1.0 - ((buffer_width - sw) / buffer_width);
			}
			else {
				var sc = buffer_width / render_width;
				var sh = render_height * sc;
				
				py *= 1.0 - ((buffer_height - sh) / buffer_height);
			}
		}
		
		// Reverse-project the point into view space:
		var point_far = matrix_transform_vertex(eye_id.get_inverse_projection_matrix(), px, py, 1, 1);	// Location at far-clip
		var point_near = matrix_transform_vertex(eye_id.get_inverse_projection_matrix(), px, py, 0, 1);	// Location at near-clip
		
		for (var i = 0; i < 3; ++i){ // Scale by w
			point_far[i] /= point_far[3];
			point_near[i] /= point_near[3];
		}
		
		// Project from view space into world space:
		point_far = matrix_transform_vertex(eye_id.get_inverse_view_matrix(), point_far[0], point_far[1], point_far[2], 1);
		point_near = matrix_transform_vertex(eye_id.get_inverse_view_matrix(), point_near[0], point_near[1], point_near[2], 1);
		
		ray.orientation = vec_normalize(vec(point_far[0] - point_near[0], point_far[1] - point_near[1], point_far[2] - point_near[2]));
	}
	#endregion
	
	#region INIT
	// Register the eye so it is cleaned up along with this instance:
	add_child_ref(eye_id.generate_unique_hash());
	#endregion
}