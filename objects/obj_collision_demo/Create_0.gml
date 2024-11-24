#region PROPERTIES
// Define render size (will be auto-updated w/ the GUI)
render_width = display_get_gui_width();
render_height = display_get_gui_height();

cursor = cr_arrow;
#endregion

#region METHODS
#endregion

#region INIT
#region GUI INIT
var ax = display_get_gui_width() - 12 - 256;
var ay = display_get_gui_height() - 12 - 44;
var inst;
inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Exit";
inst.signaler.add_signal("pressed", new Callable(id, game_end));

ay -= 44;
inst = instance_create_depth(ax, ay, 0, obj_button);
inst.text = "Render Test";
inst.signaler.add_signal("pressed", new Callable(id, function(){
	instance_destroy(obj_menu_item);
	instance_destroy();
	
	instance_create_depth(0, 0, 0, obj_render_demo);
}));
#endregion
#endregion