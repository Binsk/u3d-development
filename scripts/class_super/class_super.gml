/// ABOUT
/// A special struct that helps implement function inheritence by marking and 
/// executing parent functions on behalf of its owner class.

/// @desc	creates a new function recorder for the structure 'class'.
function Super(class) constructor {
	#region PROPERTIES
	self.class = class;
	data = {};
	#endregion
	
	#region METHODS
	/// @desc	Marks a function name to be recorded into the super. This should be
	///			done just before overriding a parent function so as to store the parent's version.
	function mark(name=""){
		if (is_undefined(class[$ name]))
			throw new Exception(string_ext("failed to mark [{0}] as super; method doesn't exist!", [name]));
		
		var array = data[$ name] ?? [];
		array_push(array, class[$ name]);
		data[$ name] = array;
	}
	
	/// @desc	Executes the parent's version of the specified function name, if available.
	///			This works similarly to event_inherited(), only for arbitrary function names.
	///			This will return whatever the parent function returns, or undefined.
	/// @param	{string}	name		  the name of the parent function to call
	/// @param	{array}	 argv=[]		  array of arguments to pass into the parent function
	/// @param	{int}	   offset=0		the offset in the array to start reading from
	/// @param	{int}	   count=all	 the number of array elements to pass in
	function execute(name, argv=[], offset=0, count=infinity){
		var array = data[$ name];
		if (is_undefined(array)) // Nothing to execute
			return;
		
		// Record array index offset to make sure we don't get in an infinite loop
		// w/ chains of super calls.
		var index_offset = self[$ "process_offset"] ?? 0;
		
		// Trying to access too deep into the parent functions (shouldn't really be possible)
		if (array_length(array) <= index_offset){
			if (process_offset - 1 <= 0)
				struct_remove(self, "process_offset");
				
			return undefined;
		}
		
		// Grab the function in the scope of our owner:
		var parent_method = method(class, array[array_length(array) - 1 - index_offset]);
		process_offset = index_offset + 1; // Mark for any recursive calls
		// Execute while passing in specified arguments:
		var return_value = method_call(parent_method, argv, offset, max(0, min(count - offset, array_length(argv))));
		process_offset--; // Decrement in case we have multiple calls in the same function
		
		// Remove if back to root
		if (process_offset <= 0)
			struct_remove(self, "process_offset");
		
		// Retrun the result of teh parent function
		return return_value;
	}
	#endregion
}