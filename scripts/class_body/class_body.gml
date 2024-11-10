/// @about
/// A body represents a 3D thing in the scene. It can contain a model, collision
/// shape, and handle various interactions and signals.

function Body() : Node() constructor {
	#region PROPERTIES
	model_instance = undefined;			// Renderable 3D Model()
	animation_instance = undefined;		// AnimationTree() to apply to the model
	collidable_instance = undefined;	// Collidable() to apply to the model
	#endregion
	
	#region METHODS
	/// @desc	Assigns a Model() to the body to render. The body must still be
	///			added to obj_render_controller first in order to be processed
	///			by the cameras.
	function set_model(model){
		if (not is_instanceof(model, Model)){
			Exception.throw_conditional("invalid type, expected [Model]!");
			return;
		}
		
		replace_child_ref(model, model_instance);
		model_instance = model;
	}
	
	/// @desc	Assigns an AnimationTree() to apply to the Model() attached to
	///			this body. The AnimationTree() should be attached to the
	///			obj_animation_controller, but it can also manually be processed
	///			on-demand.
	function set_animation(tree){
		if (not is_instanceof(tree, AnimationTree)){
			Exception.throw_conditional("invalid type, expected [AnimationTree]!");
			return;
		}
		
		replace_child_ref(tree, animation_instance);
		animation_instance = tree;
	}
	
	function set_collidable(collidable){
		if (not is_instanceof(collidable, Collidable)){
			Exception.throw_conditional("invalid type, expected [Collidable]!");
			return;
		}
		
		replace_child_ref(collidable, collidable_instance);
		collidable_instance = collidable;
		set_data("collision", undefined);	// Remove cached collidable data
	}
	
	function get_model(){
		return model_instance;
	}
	
	function get_animation(){
		return animation_instance;
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		model_instance = undefined;
	}
	#endregion
}