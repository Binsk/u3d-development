/// @about
/// A generic menu item that can represent a button, slider, or anything else 
/// that requires some form of mouse interaction.

#region PROPERTIES
signaler = new Signaler();	// Used to signal interactions
is_hovered = false;	// Whether or not the mouse is over this instance
is_disabled = false;
text = "";				// The text to display on behalf of this instance
text_tooltip = "";		// The text (if any) to display in the tooltip when hovered
anchor = new Anchor2D();

color_bright = c_white;			// Static bright; text and the like
color_bright_disabled = c_gray;
color_primary = make_color_rgb(24 + 12, 24 + 12, 48 + 24);	// Background color
color_primary_disabled = make_color_rgb(24, 24, 24);
color_hovered = make_color_rgb(24 + 32, 24 + 32, 48 + 64);	// Interaction color
color_highlight = c_yellow;	// Selected / Grabbed color
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
controller_id = noone;
with (obj_render_demo)
	other.controller_id = id;

with (obj_collision_demo)
	other.controller_id = id;
	
	// X-Axis
if (x > controller_id.render_width * 0.5){
	anchor.anchor.x1 = 1.0;
	anchor.margin.x1 = x - controller_id.render_width;
}
else {
	anchor.anchor.x1 = 0.0;
	anchor.margin.x1 = x;
}

	// Y-Axis
if (y > controller_id.render_height * 0.5){
	anchor.anchor.y1 = 1.0;
	anchor.margin.y1 = y - controller_id.render_height;
}
else {
	anchor.anchor.y1 = 0.0;
	anchor.margin.y1 = y;
}

x = anchor.get_x(controller_id.render_width);
y = anchor.get_y(controller_id.render_height);
#endregion