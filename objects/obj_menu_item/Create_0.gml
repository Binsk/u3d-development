/// @about
/// A generic menu item that can represent a button, slider, or anything else 
/// that requires some form of mouse interaction.

#region PROPERTIES
signaler = new Signaler();	// Used to signal interactions
is_hovered = false;	// Whether or not the mouse is over this instance
text = "";				// The text to display on behalf of this instance
text_tooltip = "";		// The text (if any) to display in the tooltip when hovered
anchor = new Anchor2D();
#endregion

#region METHODS
function set_anchor(anchor){
	if (not is_instanceof(anchor, Anchor2D))
		throw new Exception("invalid type, expected [Anchor2D]!");
	
	self.anchor = anchor;
}

function get_anchor(){
	return anchor;
}
#endregion 

#region INIT
// Take the defined x/y position and convert to anchor positions so that they
// will auto-update w/ GUI changes. This was added later so it is a bit of a 
// hacky way of adapting things as we don't actually use the anchors to define
// the element shape.

	// X-Axis
if (x > obj_demo_controller.render_width * 0.5){
	anchor.anchor.x1 = 1.0;
	anchor.margin.x1 = x - obj_demo_controller.render_width;
}
else {
	anchor.anchor.x1 = 0.0;
	anchor.margin.x1 = x;
}

	// Y-Axis
if (y > obj_demo_controller.render_height * 0.5){
	anchor.anchor.y1 = 1.0;
	anchor.margin.y1 = y - obj_demo_controller.render_height;
}
else {
	anchor.anchor.y1 = 0.0;
	anchor.margin.y1 = y;
}
#endregion