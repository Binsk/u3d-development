/// @about
/// A body represents a 3D thing in the scene and is the core structure used
/// by the controller systems. Bodies can contain models, animation trees, 
/// and collisions and a number of systems, such as the Camera, is based off
/// of the Body class.

/// @signals
///		"set_collidable"	(from, to)		-	thrown when a new collidable is assigned
///		"set_model"			(from, to)		-	thrown when a new model is assigned

function Body() : Node() constructor {
	#region PROPERTIES
	model_instance = undefined;			// Renderable 3D Model()
	animation_instance = undefined;		// AnimationTree() to apply to the model
	collidable_instance = undefined;	// Collidable() to apply to the model
	#endregion
	
	#region METHODS
	/// @desc	Assigns a Model() to the body to render. In order to render,
	///			this instance must be added to the render controller.
	function set_model(model){
		if (not is_instanceof(model, Model)){
			Exception.throw_conditional("invalid type, expected [Model]!");
			return;
		}
		
		var m_old = model_instance;
		self.replace_child_ref(model, model_instance);
		model_instance = model;
		signaler.signal("set_model", [m_old, model]);
	}
	
	/// @desc	Assigns an AnimationTree() to apply to the Model() attached to
	///			this body. In order to animate, this instance must be added to
	///			the animation controller.
	function set_animation(tree){
		if (not is_instanceof(tree, AnimationTree)){
			Exception.throw_conditional("invalid type, expected [AnimationTree]!");
			return;
		}
		
		self.replace_child_ref(tree, animation_instance);
		animation_instance = tree;
	}
	
	/// @desc	Assigns a Collidable() to the body. In order to detect collisions, this
	///			instance must be added to the collision controller.
	function set_collidable(collidable){
		if (not is_instanceof(collidable, Collidable)){
			Exception.throw_conditional("invalid type, expected [Collidable]!");
			return;
		}
		
		var c_old = collidable_instance;
		self.replace_child_ref(collidable, collidable_instance);
		collidable_instance = collidable;
		self.set_data("collision", undefined);	// Remove cached collidable data
		signaler.signal("set_collidable", [c_old, collidable]);
	}
	
	/// @desc	Returns the currently attached Model.
	/// @return	{Model}
	function get_model(){
		return model_instance;
	}
	
	/// @desc	Returns the currently attached AnimationTree.
	/// @return {AnimationTree}
	function get_animation(){
		return animation_instance;
	}
	
	/// @desc	Retruns the currently attached Collidable.
	function get_collidable(){
		return collidable_instance;
	}
	
	super.register("free");
	function free(){
		super.execute("free");
		model_instance = undefined;
		animation_instance = undefined;
		collidable_instance = undefined;
	}
	#endregion
}