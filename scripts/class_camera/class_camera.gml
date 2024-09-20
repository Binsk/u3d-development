/// ABOUT
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
function Camera() : Node() constructor{
	#region PROPERTIES
	anchor = new CameraAnchor(self);
	tonemap = CAMERA_TONEMAP.none;
	exposure = 1.0;		// (only applies when tonemap != none), the exposure level for the camera
	
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
		return matrix_build_lookat(position.x, position.y, position.z, to.x, to.y, to.z, up.x, up.y, up.z);
	}
	
	/// @desc	Build the projection matrix required for this camera.
	function get_projection_matrix(){
/// @stub	Build proper projection matrix for platforms
		return matrix_build_identity();
	}
	
	function generate_gbuffer(){
		if (not surface_exists(application_surface))
			return;
			
		/// @note	the depth texture doesn't have its own surface as it is
		///			taken from the depth buffer of the albedo surface
		var screen_width = surface_get_width(application_surface);
		var screen_height = surface_get_height(application_surface);
		var buffer_width = anchor.get_dx(screen_width);
		var buffer_height = anchor.get_dy(screen_height);
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