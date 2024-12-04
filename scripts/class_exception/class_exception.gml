/// @about
/// A simple data container to help display and determine custom exception types.
/// Special types should inherit and be determined through is_instanceof() but the
/// generic 'index' property can also be used to help distinguish types.
///
/// Instead of using `throw new Exception()` the static function
/// `Exception.throw_conditional()` can also be used. The later of these options
///	will take into account the static SILENT_THROW setting where, if true, an
/// error will NOT be thrown but it will still be printed out to the console.
/// Note that this can cause unexpected problems if the code afterwards does
/// not handle the error.
///
/// Having throw disabling is useful if you wish to have super-strict error
/// tracking when debugging but wish to supress them and handle things through
/// value checks upon release.

/// @desc	An exception class that can contain / display an error message.
/// @param	{string}	message		an error message to display if the exception isn't caught
/// @param	{real}		index		a generic index to help identify exception type
function Exception(message=undefined, index=0) constructor {
	#region PROPERTIES
	static SILENT_THROW = false;	// If true, the exception WON'T throw through throw_conditional(), but instead print to console
	self.message = string(message ?? "<unknown>");
	self.index = index;
	#endregion
	
	#region STATIC METHODS
	/// @desc	Performs the same as `throw new Exception(message, index)`, except
	///			it regards the SILENT_THROW setting.
	static throw_conditional = function(message, index=0, class=Exception, pop_value=0){
		var exception = new class(message, index);
		exception._update_message(2 + pop_value); // Pop throw_conditional() off of the stack trace for cleaner reporting
		
		// Print out to console:
		var marker = "";
		repeat (3) // Because it starts getting ugly having massive strings in the code
			marker += "################################"; // 32 symbols
			
		show_debug_message(string_ext("{1}\n{0}\n{1}", [exception.longMessage, marker]));
		
		// If silent, now need to throw an actual exception:
		if (SILENT_THROW){
			delete exception;
			return;
		}
		
		// Not silent, throw as normal
		throw exception;
	}
	#endregion
	#region METHODS
	/// @desc	Regenerates the exception message w/ the trace.
	/// @param	{real}	debug_pop	number of messages to pop off the end of the call stack
	function _update_message(debug_pop=0){
		stacktrace = debug_get_callstack();

		if (debug_pop > 0)
			array_delete(stacktrace, 0, debug_pop);
			
		var script_data = string_split(stacktrace[0], ":");
		script = script_data[0];
		if (array_length(script_data) > 1)
			line = script_data[1];
		else
			line = "[?]";
		
		longMessage = string_ext("[Upset 3D Trace]\nin {0}, (line {1})\n{2}\nTrace:\n  {3}", [script, line, self.message, array_glue("\n  ", stacktrace, 0, -2)]);
	}
	
	/// @desc	Returns the specified exception index stored by this exception.
	function get_index(){
		return index;
	}
	
	/// @desc	Returns the error message without any of the tracing or formatting.
	function get_message(){
		return message;
	}
	
	function toString(){
		// toString is generally used to help print things out whet GameMaker's actual error display
		// takes over.
		//
		// To print out the message more cleanly and manually the value `longMessage` is the better option.
		return string_ext("\n============\n[Upset 3D Trace]\n{0}\nTrace:\n  {1}\n============", [message, array_glue("\n  ", stacktrace, 0, -2)]);
	}
	#endregion
	
	#region INIT
	_update_message(2);
	#endregion
}