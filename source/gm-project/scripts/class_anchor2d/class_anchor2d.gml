/// @about
/// A generic 2D anchor that stores the shape of a rectangle in 2D space based off of
/// anchors and margins.
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
	/// @desc	Sets the anchor points of the rectangle corners.
	///			You can think of these as percentages across.
	/// @param	{real}	x1
	/// @param	{real}	y1
	/// @param	{real}	x2
	/// @param	{real}	y2
	function set_anchors(x1, y1, x2, y2){
		anchor.x1 = x1;
		anchor.x2 = x2;
		anchor.y1 = y1;
		anchor.y2 = y2;
	}
	
	/// @desc	Sets the margin points of the rectangle corners.
	///			You can think of these as pixel offsets from the anchors.
	/// @param	{real}	x1
	/// @param	{real}	y1
	/// @param	{real}	x2
	/// @param	{real}	y2
	function set_margins(x1, y1, x2, y2){
		margin.x1 = x1;
		margin.x2 = x2;
		margin.y1 = y1;
		margin.y2 = y2;
	}
	
	///	@desc	Returns the x1 value in relation to a specified canvas size.
	function get_x(canvas_width){
		return canvas_width * anchor.x1 + margin.x1;
	}

	///	@desc	Returns the y1 value in relation to a specified canvas size.
	function get_y(canvas_height){
		return canvas_height * anchor.y1 + margin.y1;
	}
	
	/// @desc	Returns the number of pixels between x1 and x2.
	function get_dx(canvas_width){
		return (canvas_width * anchor.x2 + margin.x2) - (canvas_width * anchor.x1 + margin.x1);
	}
	
	/// @desc	Returns the number of pixels betwen y1 and y2.
	function get_dy(canvas_height){
		return (canvas_height * anchor.y2 + margin.y2) - (canvas_height * anchor.y1 + margin.y1);
	}
	
	/// @desc	Returns the x-position given a canvas size and percentage across the rectangle.
	function get_lx(lerpvalue, canvas_width){
		return get_x(canvas_width) + get_dx(canvas_width) * lerpvalue;
	}
	
	/// @desc	Retruns the y-position given a canvas size and percentage across the rectangle.
	function get_ly(lerpvalue, canvas_height){
		return get_y(canvas_width) + get_dy(canvas_width) * lerpvalue;
	}
	#endregion
}