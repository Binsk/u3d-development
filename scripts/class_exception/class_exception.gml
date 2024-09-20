/// ABOUT
/// A simple data container to help display and determine custom exception types.
/// Special types should inherit and determined through is_instanceof() but the
/// generic 'index' property can also be used to help distinguish types.

/// @desc	An exception class that can contain / display an error message.
/// @param	{string}	message	an error message to display if the exception isn't caught
/// @param	{int}	   index=0	  a generic index to help identify exception type
function Exception(message=undefined, index=0) constructor {
	#region PROPERTIES
	self.message = string(message ?? "<unknown>");
	self.index = index;
	#endregion
	
	#region METHODS
	function get_index(){
		return index;
	}
	
	function toString(){
		return string_ext(":\n[Upset 3D Trace]\n{0}", [message]);
	}
	#endregion
	
	#region INIT
	var stack_trace = debug_get_callstack();
	var script_data = string_split(stack_trace[1], ":");
	script = script_data[0];
	line = script_data[1];
	stacktrace = debug_get_callstack();
	
	var long = "";
	for (var i = array_length(stacktrace) - 2; i > 0; --i)
		long += stack_trace[i] + "\n";
	
	longMessage = string_ext("Upset 3D error in {0}, line {1}\n\n{2}\n-----------------------\n{3}", [script, line, self.message, long]);
	#endregion
}