/// @about
/// A generic data container for U3D systems to inherit from to guarantee base
/// system elements are available, such as index numbers and metadata functions.
///
/// ALL U3DObject types and their children must call free() before being deleted
/// to prevent memory leaks.

/// SIGNALS
///		"free" ()	-	Thrown when 'free' is called, before any code is executed
function U3DObject() constructor {
	#region PROPERTIES
	static INDEX_COUNTER = int64(0);	// Generic data index for quick comparisons
	index = INDEX_COUNTER++;			// Unique identifier, should never be modified directly
	super = new Super(self);			// Used to fake function inheritance
	signaler = new Signaler();			// Used to tell other structs when things occur
	#endregion
	
	#region STATIC METHODS
	#endregion
	
	#region METHODS 
	/// @desc	Return the unique index for the instance.
	function get_index(){
		return index;
	}
	
	/// @desc	Returns if the provided data is the exact same data as this calling
	///			instance.
	function is_equal(data){
		if (not is_struct(data))
			return false;
		
		return (data[$ "index"] ?? -1) == get_index();
	}

	/// @desc	Frees up all data related to the object and makes the object 'unusable' from
	///			this point forward. Can be seen as the 'destructor' for the class. This should
	///			ALWAYS be called before delete <variable>.
	function free(){
		signaler.signal("free");
		signaler.clear();
		
		delete signaler;
		delete super;
	}
	#endregion
	
	#region INIT
	#endregion
}