/// @about	Creates a new signaler system that can execute multiple methods
///         at a time while passing optional static and dynamic arguments.
///
///         Signalers can be slow to create / destroy but they are fast to 
///         execute. Excessive addition / removal of signals can cause slow-down
///         and should be minimized as much as possible.
///
///         Signals can accept either regular method() structures or Callable()
///			structures which allow pre-defining arguments. When removing a signal
///			the same structure must be provided along with the argument values used
///			when attached.
///
///			Callable() structures are compared based on their contained values and
///			not their references. Any Callable() structures attached will be auto-deleted
///			upon detaching. If this is undesired, a duplicate of your Callable() should
///			be attached instead.
function Signaler() constructor{
	#region MEMBERS
	signal_map = {}; // signal -> ref pairs
	#endregion
	
	#region METHODS
	/// @desc   Cleans the signaler, removing all attached signals.
	function clear(){
		var array = struct_get_names(signal_map);
		for (var i = array_length(array) - 1; i >= 0; --i)
			clear_label(array[i]);
	}
	
	/// @desc   Cleans the signaler, removing all attached signals for a given label.
	/// @param  {string}    label
	/// @return {bool}  	whether or not the signal map was changed
	function clear_label(name=""){
		
		var array = signal_map[$ name];
		if (is_undefined(array))
			return false;
		
		for (var i = 0; i < array_length(array); ++i)
			delete array[i];
		
		struct_remove(signal_map, name);
		return true;
	}
	
	/// @desc   Returns whether the specified signal is defined in the system.
	/// @param  {string}    name		name of the signal that was added
	/// @param  {method}    method      method/callable of the signal that was added
	/// @return {bool}      true if success
	function signal_exists(_name, _method){
		var array = signal_map[$ _name];
		if (is_undefined(array))
			return false;
		
		var callable = (is_instanceof(_method, Callable) ? _method : new Callable(method_get_self(_method), method_get_index(_method)));
		for (var i = array_length(array) - 1; i >= 0; --i){
			if (array[i].is_equal(callable))
				return true;
		}
		
		return false;
	}


	/// @desc   Takes a method or Callable and ties it to a string label so that it
	///			it is executed whenever the specified label is triggered.
	/// @param  {string}    name        name to give the signal
	/// @param  {method}    method      method/callale to execute upon call
	function add_signal(_name, _method){
		if (not is_method(_method) and not is_instanceof(_method, Callable)){
			Exception.throw_conditional("[argument1] invalid type, expected [method] or [Callable]!");
			return;
		}
		
		// Grab our signal array:
		var array = (signal_map[$ _name] ?? []);
		array_push(array, is_instanceof(_method, Callable) ? _method : new Callable(method_get_self(_method), method_get_index(_method)));
		
		signal_map[$ _name] = array;
	}
	
	/// @desc	Performs the same as add_signal() except the signal is added to the front
	///			of the execution order.
	function add_signal_front(_name, _method){
		if (not is_method(_method) and not is_instanceof(_method, Callable)){
			Exception.throw_conditional("[argument1] invalid type, expected [method] or [Callable]!");
			return;
		}
		
		// Grab our signal array:
		var array = (signal_map[$ _name] ?? []);
		array = array_concat([is_instanceof(_method, Callable) ? _method : new Callable(method_get_self(_method), method_get_index(_method))], array);
		
		signal_map[$ _name] = array;
	}
	
	/// @desc   Removes a signal from the signaling system. The method/callable must
	///			specify the exact same data as when it was added in order to successfully
	///			remove it.
	/// @param  {string}    name        name of the signal that was added
	/// @param  {method}    method      method of the signal that was added
	/// @return {bool}      true if success
	function remove_signal(_name, _method){
		var array = signal_map[$ _name];
		if (is_undefined(array)) 
			return false;
			
		var callable = (is_instanceof(_method, Callable) ? _method : new Callable(method_get_self(_method), method_get_index(_method)));
		
		var found_value = false;
		for (var i = array_length(array) - 1; i >= 0; --i){
			if (array[i].is_equal(callable)){
				delete array[i];
				array_delete(array, i, 1);
				found_value = true;
			}
		}
		
		signal_map[$ _name] = array;
		return found_value;
	}

	/// @desc   Triggers a signal, if it exists, and overrides any pre-specified
	///			arguments with the specified argument array.
	/// @param  {string}    name        name of the signal to trigger
	/// @param  {array}     argv=[]     argument array to pass
	function signal(name, argv=[]){
		// Look up our signal:
		var array = array_duplicate_shallow(signal_map[$ name]);
		if (is_undefined(array)) 
			return; // No signal w/ this name
			
		// Loop through each attached signal:
		var loop = array_length(array);
		for (var i = 0; i < loop; ++i){
			var callable = array[i];
			callable.call(argv);
		}
	}
	
	/// @desc   Convert-to-string override to print out some useful signal data
	///         if required.
	function toString(){
		return string_ext("[signaler:{0}]", [struct_names_count(signal_map)]);
	}
	#endregion
}

/// @desc	A callable is effectively a method() that can also take arguments which will
///			be auto-passed when called.
/// @warning	Due to the identifier hash, passing in a large struct as an instance or argv
///				value may cause a slow construction! Override the struct's toString() to mitigate this.
/// @param	{any}			instance	the instance / struct to call in the contect of
/// @param	{function}		function	the function to call when executed
/// @param	{array}			argv=[]		the arguments to pass when executed
function Callable(_instance, _function, argv=[]) constructor {
		#region PROPERTIES
		method_ref = undefined;
		identifier = "";
		self.argv = argv;
		#endregion
		
		#region METHODS
		function get_method(){
			return method_ref;
		}
		
		/// @desc	Executes the Callable. Any arguments passed will OVERRIDE the currently
		///			stored argv values! E.g., if you created the callable with argv=[1, 2]
		///			and executed call([2]) then the system would execute with argv=[2, 2]
		///			If a value is undefined then the default pre-defined value will be
		///			substituted in.
		function call(argv=[]){
			var other_loop = array_length(argv);
			var loop = max(array_length(self.argv), other_loop);
			var nargv = array_create(loop);
			for (var i = 0; i < loop; ++i){
				if (i < other_loop)
					nargv[i] = argv[i];
				else
					nargv[i] = self.argv[i];
			}

			method_call(method_ref, nargv);
		}
		
		/// @desc	Returns if the specified callable contains the same data.
		/// @param	{Callable}	callable	callable instance to check against
		/// @return	{bool}
		function is_equal(callable){
			if (not is_instanceof(callable, Callable))
				return false;
				
			return identifier == callable.identifier;
		}
	
		function is_valid(){
			if (is_undefined(method_ref))
				return false;
			
			var mself = method_get_self(method_ref);
			if (is_struct(mself))
				return true;
			
			if (is_undefined(mself))
				return false;
			
			return instance_exists(mself);
		}
	
		/// @desc	Creates an identical copy of this callable instance.
		/// @return {Callable}
		function duplicate(){
			return new Callable(method_get_self(method_ref), method_get_index(method_ref), array_duplicate_shallow(argv));
		}
		#endregion

		#region INIT
		identifier = md5_string_utf8(string(_instance) + string(_function) + string(argv));
		
		// Special-case if the instance is freed, called by signal, which calls this Callable.
		if (is_struct(_instance) or instance_exists(_instance))
			method_ref = method(_instance, _function);
			
		#endregion
}