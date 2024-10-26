/// @about
/// A body represents a 3D thing in the scene. It can contain a model, collision
/// shape, and handle various interactions and signals.

function Body() : Node() constructor {
	#region PROPERTIES
	model_instance = undefined;			// Renderable 3D model
	#endregion
	
	#region METHODS
	function set_model(model){
		if (not is_instanceof(model, Model)){
			Exception.throw_conditional("invalid type, expected [Model]!");
			return;
		}
		
		model_instance = model;
		add_child_ref(model);
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		model_instance = undefined;
	}
	#endregion
	
	#region INIT
	#endregion
}