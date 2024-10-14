/// @about
/// A generic data container for U3D systems to inherit from to guarantee base
/// system elements are available, such as index numbers and metadata functions.
///
/// ALL U3DObject types and their children must call free() before being deleted
/// to prevent memory leaks.
///
/// Dynamically generated resources, such as textures and materials from glTF files,
/// will be given a hash and auto-managed so long as the base Model is freed. If
///	you need to use materials or auto-generated data outside of the generated scope
/// then you can increase the reference number while using it and then decrease it
/// once done to let the system free it up when appropriate.

/// SIGNALS
///		"free" ()		-	Thrown when 'free' is called.
///		"cleanup" ()	-	Thrown when 'cleanup' is called.
function U3DObject() constructor {
	#region PROPERTIES
	static INDEX_COUNTER = int64(0);	// Generic data index for quick comparisons
	is_freed = false;					// Once freed, this is set to true where NOTHING SHOULD BE USED AT THIS POINT
	index = INDEX_COUNTER++;			// Unique identifier, should never be modified directly
	super = new Super(self);			// Used to fake function inheritance
	signaler = new Signaler();			// Used to tell other structs when things occur
	hash = undefined;			// Used for garbage clean-up with automatically generated resources
	#endregion
	
	#region STATIC METHODS
	/// @desc	Cleans up the data for the specified hash. Note that the hash MUST be valid,
	///			and all references removed!
	static cleanup_reference = function(hash){
		if (is_undefined(hash))
			throw new Exception("cannot cleanup static resource!");
		
		if (U3D.MEMORY[$ hash].count != 0)
			throw new Exception($"cannot cleanup reference, [{U3D.MEMORY[$ hash].count}] occurrences still exist!");
		
		var data = U3D.MEMORY[$ hash].data;
		struct_remove(U3D.MEMORY, hash);
		
		if (not U3DObject.get_is_valid_object(data))
			return;
			
		data.signaler.signal("cleanup");
		data.cleanup();
		data.hash = undefined;
	}
	
	/// @desc	Returns the data (aka., U3DObject instance) monitored w/ the specified
	///			hash value.
	static get_reference_data = function(hash){
		if (is_undefined(hash))
			return undefined;
			
		return U3D.MEMORY[$ hash];
	}
	
	/// @desc	Returns if the specified value is a valid U3DObject. This checks for
	///			struct existance as well as freed state.
	static get_is_valid_object = function(value){
		if (not is_struct(value))
			return false;
			
		if (not is_instanceof(value, U3DObject))
			return false;
		
		if (value[$ "is_freed"] ?? true)
			return false;
		
		return true;
	}
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
	
	/// @desc	Returns the number of references to this instance. ONLY applies to 
	///			dynamically allocated resources w/ a memory hash. 
	function get_reference_count(){
		if (is_undefined(hash))
			return 0;
		
		return U3D.MEMORY[$ hash].count;
	}
	
	/// @desc	Increment the reference count if dynamically loaded. Do NOT CALL THIS
	///			unless you know exactly what you are doing!
	function increment_reference(){
		if (is_undefined(hash)) // Not dynamically added; no need
			return;
		
		if (is_undefined(U3D.MEMORY[$ hash])){
			U3D.MEMORY[$ hash] = {
				data : undefined,
				count : 1
			}
			
			U3D.MEMORY[$ hash].data = self;
		}
		else
			U3D.MEMORY[$ hash].count += 1;
	}
	
	/// @desc	Decrements the reference count and cleans up the data if appropriate.
	function decrement_reference(){
		if (is_undefined(hash))
			return;
		
		if (is_undefined(U3D.MEMORY[$ hash]))
			return;
			
		U3D.MEMORY[$ hash].count -= 1;
		if (U3D.MEMORY[$ hash].count == 0){
			U3DObject.cleanup_reference(hash);
			hash = undefined;
		}
	}
	
	/// @desc	The cleanup function is called by dynamic resources once all references
	///			are removed. It should NEVER be called directly.
	function cleanup(){
		free();
	};


	/// @desc	Frees up all data related to the object and makes the object 'unusable' from
	///			this point forward. Can be seen as the 'destructor' for the class. This should
	///			ALWAYS be called before delete <variable>.
	function free(){
		if (not U3DObject.get_is_valid_object(self))
			return;
			
		signaler.signal("free");
		signaler.clear();
		
		delete signaler;
		delete super;
		
		is_freed = true;
	}
	#endregion
	
	#region INIT
	#endregion
}