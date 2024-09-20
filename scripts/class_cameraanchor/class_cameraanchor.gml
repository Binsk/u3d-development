/// ABOUT
/// A camera anchor specifies where on the screen the specified camera instance
/// should be rendered.
function CameraAnchor(camera) constructor {
	#region PROPERTIES
	anchor = {
		x1 : 0,
		y1 : 0,
		x2 : 1,
		y2 : 1
	};
	
	margin = {
		x1 : 0,
		y1 : 0,
		x2 : 0,
		y2 : 0
	};
	
	self.camera = camera;
	#endregion
	
	#region METHODS
	function set_anchors(x1, y1, x2, y2){
		anchor.x1 = x1;
		anchor.x2 = x2;
		anchor.y1 = y1;
		anchor.y2 = y2;
	}
	
	function set_margins(x1, y1, x2, y2){
		margin.x1 = x1;
		margin.x2 = x2;
		margin.y1 = y1;
		margin.y2 = y2;
	}
	
	function get_dx(canvas_width){
		return (canvas_width * anchor.x2 + margin.x2) - (canvas_width * anchor.x1 + margin.x1);
	}
	
	function get_dy(canvas_height){
		return (canvas_width * anchor.y2 + margin.y2) - (canvas_width * anchor.y1 + margin.y1);
	}
	#endregion
	
	#region INIT
	if (not is_instanceof(camera, Camera))
		throw new Exception("invalid type, expected [Camera]!");
	#endregion
}