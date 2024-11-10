/// @about
/// A generic 2D anchor that stores a 2D position based on anchor points + margins.
function Anchor2D() constructor {
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
	
	function get_x(canvas_width){
		return canvas_width * anchor.x1 + margin.x1;
	}

	function get_y(canvas_height){
		return canvas_height * anchor.y1 + margin.y1;
	}
	
	function get_dx(canvas_width){
		return (canvas_width * anchor.x2 + margin.x2) - (canvas_width * anchor.x1 + margin.x1);
	}
	
	function get_dy(canvas_height){
		return (canvas_height * anchor.y2 + margin.y2) - (canvas_height * anchor.y1 + margin.y1);
	}
	
	function get_lx(lerpvalue, canvas_width){
		return get_x(canvas_width) + get_dx(canvas_width) * lerpvalue;
	}
	
	function get_ly(lerpvalue, canvas_height){
		return get_y(canvas_width) + get_dy(canvas_width) * lerpvalue;
	}
	#endregion
}