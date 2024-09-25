/// @about
/// A 3D camera that handles rendering for a specific view in 3D space.
/// Can assume to look down the x+ axis w/ a y+up value

/// @desc defines the necessary buffers we will need for the graphics pipeline
///		  for this camera.
enum CAMERA_GBUFFER {
	albedo,		// Albedo color (rgba8unorm)
	depth,		// Depth map; taken from albedo
	normal,		// Normal map (rg8unorm); z-axis re-constructed in-shader
	pbr,		// PBR properties (rgba8unorm); roughness, metallic, specularity (alpha unused)
}

/// @desc	defines the tonemapping to use for the camera; 'none' is a straight
///			render while every other option will enable HDR and 4x the vRAM usage
enum CAMERA_TONEMAP {
	none,
}

/// @desc	Creates a new 3D camera that can be moved around the world and added
///			to the rendering pipeline.
function Camera(znear=0.01, zfar=1024, fov=50) : Node() constructor{
	#region PROPERTIES
	anchor = new CameraAnchor(self);
	tonemap = CAMERA_TONEMAP.none;
	exposure = 1.0;		// (only applies when tonemap != none), the exposure level for the camera
	buffer_width = undefined;
	buffer_height = undefined;
	self.znear = znear;
	self.zfar = zfar;
	self.fov = fov;
	
	gbuffer = {
		surfaces : {},
		textures : {}
	};
	#endregion
	
	#region METHODS
	/// @desc	Returns the camera anchor attached to this camera.
	function get_anchor(){
		return anchor;
	}
	
	/// @desc	Build the view matrix required for this camera.
	function get_view_matrix(){
		var forward = get_forward_vector();
		var up = get_up_vector();
		var to = vec_add_vec(position, forward);
		// up = vec(0, 1, 0);
		return matrix_build_lookat(position.x, position.y, position.z, to.x, to.y, to.z, up.x, up.y, up.z);
	}
	
	/// @desc	Build the projection matrix required for this camera.
	function get_projection_matrix(){
		if (is_undefined(buffer_width)) // Cannot determine render size
			return matrix_build_identity();
		
		var aspect = buffer_width / buffer_height;
			// Auto FOV is subjective and arbitrary; this calculates a value I personally
			// found pleasant for simple 3rd person games.
		// if (is_undefined(fov))
		// 	fov = max(lerp(110, 72, aspect), 10) + 10;
			
		var yfov = -2 * arctan(dtan(fov/2) * aspect);
		
		if (get_is_directx_pipeline())
			aspect = -aspect;
		
		var h = 1 / tan(yfov * 0.5);
		var w = h / aspect;
		var a = zfar / (zfar - znear);
		var b = (-znear * zfar) / (zfar - znear);
		var matrix = [
			w, 0, 0, 0,
			0, h, 0, 0,
			0, 0, a, 1,
			0, 0, b, 0
			];
		return matrix;
	}
	
	function set_znear(znear){
		self.znear = znear;
	}
	
	function set_zfar(zfar){
		self.zfar = zfar;
	}
	
	function set_fow(fow){
		self.fow = fow;
	}
	
	function generate_gbuffer(){
		if (not surface_exists(application_surface))
			return;
			
		/// @note	the depth texture doesn't have its own surface as it is
		///			taken from the depth buffer of the albedo surface
		var screen_width = surface_get_width(application_surface);
		var screen_height = surface_get_height(application_surface);
		buffer_width = anchor.get_dx(screen_width);
		buffer_height = anchor.get_dy(screen_height);
		var surfaces = gbuffer.surfaces;
		var textures = gbuffer.textures;
		
		// Check for existence:
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.albedo])){
			surface_depth_disable(false);
			surfaces[$ CAMERA_GBUFFER.albedo] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.albedo] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.albedo]);
			textures[$ CAMERA_GBUFFER.depth] = surface_get_texture_depth(surfaces[$ CAMERA_GBUFFER.albedo]);
		}
		
		surface_depth_disable(true);
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.normal])){
			surfaces[$ CAMERA_GBUFFER.normal] = surface_create(buffer_width, buffer_height, surface_rg8unorm);
			textures[$ CAMERA_GBUFFER.normal] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.normal]);
		}
		
		if (not surface_exists(surfaces[$ CAMERA_GBUFFER.pbr])){
			surfaces[$ CAMERA_GBUFFER.pbr] = surface_create(buffer_width, buffer_height, surface_rgba8unorm);
			textures[$ CAMERA_GBUFFER.pbr] = surface_get_texture(surfaces[$ CAMERA_GBUFFER.pbr]);
		}
		surface_depth_disable(false);
		
		// Check for resizing:
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.albedo]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.albedo]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.albedo], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.normal]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.normal], buffer_width, buffer_height);
		
		if (surface_get_width(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_width or surface_get_height(surfaces[$ CAMERA_GBUFFER.pbr]) != buffer_height)
			surface_resize(surfaces[$ CAMERA_GBUFFER.pbr], buffer_width, buffer_height);
	}
	
	/// @desc	Given an array of renderable bodies, the camera will render them
	///			out to the GBuffer.
	function render_gbuffer(body_array=[]){
/// @stub	Implement
	}
	
	super.mark("free");
	function free(){
		super.execute("free");
		
		var surfaces = gbuffer.surfaces;
		var keys = struct_get_names(surfaces);
		for (var i = array_length(keys) - 1; i >= 0; --i){
			if (surface_exists(surfaces[$ keys[i]]))
				surface_free(surfaces[$ keys[i]]);
		}
		gbuffer = {surfaces:{}, textures:{}};
		
		delete anchor;
		anchor = undefined;
	}
	#endregion
	
	#region INIT
	#endregion
}