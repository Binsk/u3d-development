/// @about
/// A body represents a 3D thing in the scene. It can contain a mesh, collision
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
		if (is_undefined(model_instance) or model.get_index() != model_instance.get_index())
			model.increment_reference();
		
		model_instance = model;
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		if (not is_undefined(model_instance))
			model_instance.decrement_reference();
		
		model_instance = undefined;
	}
	#endregion
	
	#region INIT
	#endregion
}