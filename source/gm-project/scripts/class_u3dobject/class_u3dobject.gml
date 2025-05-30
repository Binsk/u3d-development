/// @about
/// A generic data container for U3D systems to inherit from to guarantee base
/// system elements are available, such as index numbers and metadata functions.
///
/// ALL U3DObject types and their children must call free() before being deleted
/// to prevent memory leaks. They can be thought of as similar to ds_* structures
/// in terms of memory management.

/// @signals
///		"free" ()		-	Thrown when 'free' is called, by the user or the system
///		"cleanup" ()	-	Thrown when an instance is being freed automatically due to reference loss

function U3DObject() constructor {
	#region PROPERTIES
	static INDEX_COUNTER = int64(0);	// Generic data index for quick comparisons
	
	is_freed = false;					// Once freed, this is set to true where NOTHING SHOULD BE USED AT THIS POINT
	index = INDEX_COUNTER++;			// Unique identifier, should never be modified directly
	super = new Super(self);			// Used to fake function inheritance
	signaler = new Signaler();			// Used to tell other structs when things occur
	hash = undefined;					// Used for garbage clean-up with automatically generated resources
	data = {"ref":{}};					// Generic data container to hold any kind of special custom data (some internal, some user-data)
	#endregion
	
	#region STATIC METHODS
	/// @desc	Returns the data (aka., U3DObject instance) monitored w/ the specified
	///			hash value, or undefined if none exists.
	/// @param	{string}	hash
	static get_ref_data = function(hash){
		if (is_undefined(hash))
			return undefined;
			
		var data = U3D.MEMORY[$ hash];
		if (is_undefined(data))
			return undefined;
			
		return data.data;
	}
	
	/// @desc	Returns the number of references to this instance. ONLY applies to 
	///			dynamically allocated resources w/ a memory hash.
	/// @param	{string}	hash
	static get_ref_count = function(hash){
		if (is_undefined(hash))
			return 0;
		
		var data = U3D.MEMORY[$ hash];
		if (is_undefined(data))
			return 0;
			
		return data.count;
	}
	
	/// @desc	Returns if the specified value is a valid U3DObject. This checks for
	///			struct existance as well as freed state.
	/// @param	{any}	value
	static get_is_valid_object = function(value){
		if (not is_struct(value))
			return false;
			
		if (not is_instanceof(value, U3DObject))
			return false;
		
		if (value[$ "is_freed"] ?? true)
			return false;
		
		return true;
	}
	
	/// @desc	A safe way to compare if two U3DObject instances are equal. If a
	///			value is NOT a valid U3DObject the function will return false.
	///	@note	This checks index numbers no stored data, similar to comparing pointers.
	/// @param	{U3DObject}		value1
	/// @param	{U3DObject}		value2
	static are_equal = function(value1, value2){
		if (not U3DObject.get_is_valid_object(value1))
			return false;
		
		if (not U3DObject.get_is_valid_object(value2))
			return false;
		
		return value1.get_index() == value2.get_index();
	}
	#endregion
	
	#region METHODS 
	/// @desc	Generates a hash for this instance. This is NOT done for resource
	///			de-duplication as the hash is tied to the unique ID of the instance;
	///			however it can be used to auto-cleanup the instance when the parent
	///			is freed.
	/// @note	This function MUST be called before passing the instance into any
	///			other instance functions.
	function generate_unique_hash(){
		if (not is_undefined(hash))
			throw new Exception("cannot assign hash to already hashed instance!");
		
		hash = md5_string_utf8($"u3dobject_{self.get_index()}");
		U3D_GC.add_ref(self); // Add for clean-up in case this instances isn't ever actually passed into a ref
		
		return self; // Return self for function chaining
	}
	
	/// @desc	Sets a value into the custom data under the set chain of keys.
	/// @param	{array}		keys			array of string keys to set the value 
	/// @param	{any}		value=undefined	the value to set under the keys (if undefined, removes the value)
	/// @note	E.g., set_data(["foo", "bar"], "foobar") equates to self.data[$ "foo"][$ "bar"] = "foobar"
	function set_data(keys, value=undefined){
		if (not is_array(keys))
			keys = [string(keys)];
		
		var struct = data;
		var al = array_length(keys); 
		for (var i = 0; i < al; ++i){
			var sdata = struct[$ keys[i]];
			if (is_undefined(sdata)){
				sdata = {};
				struct[$ keys[i]] = sdata;
			}
			
			if (i == al - 1){
				if (is_undefined(value))
					struct_remove(struct, keys[i]);
				else
					struct[$ keys[i]] = value;
			}
			else
				struct = sdata;
		}
	}
	
	/// @desc	Fetches the value contained within the string of keys, or the default
	///			value if unset.
	/// @param	{array}		keys				array of string keys to fetch the value 
	/// @param	{any}		default=undefined	the value to return if the key doesn't exist
	function get_data(keys, default_value=undefined){
		if (not is_array(keys))
			keys = [string(keys)];
		
		var struct = data;
		var al = array_length(keys);
		for (var i = 0; i < al; ++i){
			var sdata = struct[$ keys[i]];
			if (is_undefined(sdata))
				return default_value;
			
			struct = sdata;
		}
		
		return struct;
	}
	
	/// @desc	Return the unique index for the instance.
	function get_index(){
		return index;
	}
	
	/// @desc	Returns if the provided data is the exact same data as this calling
	///			instance.
	/// @param	{any}	value
	function is_equal(data){
		if (not is_struct(data))
			return false;
		
		return (data[$ "index"] ?? -1) == self.get_index();
	}
	
	/// @desc	Increment the reference count if dynamically loaded. Do NOT CALL THIS
	///			unless you know exactly what you are doing!
	function inc_ref(){
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
	///			Do NOT CALL THIS unless you know exactly what you are doing!
	function dec_ref(){
		if (is_undefined(hash))
			return;
		
		if (is_undefined(U3D.MEMORY[$ hash]))
			return;
			
		U3D.MEMORY[$ hash].count -= 1;
		if (U3D.MEMORY[$ hash].count == 0)
			U3D_GC.add_ref(U3D.MEMORY[$ hash].data);
	}

	/// @desc	Attempts to add a U3DObject as an owned reference so that it will be
	///			auto decremented upon free. Discards duplicates and invalid instances.
	/// @param	{U3DObject}		value
	function add_child_ref(value){
		if (not U3DObject.get_is_valid_object(value))
			return false;
		
		if (is_undefined(value.hash))	// Not an auto-managed instance
			return false;
		
		if (not is_undefined(get_data(["ref", value.hash]))) // Already a child
			return false;
		
		self.set_data(["ref", value.hash], value);
		value.set_data(["ref.other", self.get_index()], self);
		value.inc_ref();
		return true;
	}

	/// @desc	Attempts to remove a U3DObject that has been registered as a child reference.
	/// @param	{U3DObject}		value
	function remove_child_ref(value){
		if (not U3DObject.get_is_valid_object(value))
			return false;
		
		if (is_undefined(value.hash))	// Not an auto-managed instance
			return false;
		
		if (is_undefined(get_data(["ref", value.hash]))) // Not a child
			return false;
		
		self.set_data(["ref", value.hash]); // Delete the data
		value.set_data(["ref.other", self.get_index()]);
		value.dec_ref();
		return true;
	}
	
	/// @desc	Replaces one reference for another; checks for duplicates and
	///			invalid references. Can handle undefined values.
	/// @param	{U3DObject}		value_new		the new instance to reference
	/// @param	{U3DObject}		value_old		the old instance to dereference
	function replace_child_ref(value_new, value_old){
		if (U3DObject.are_equal(value_new, value_old))
			return false;
		
		self.remove_child_ref(value_old);
		return self.add_child_ref(value_new);
	}
	
	/// @desc	string() override; prints out [U3DOBject:<index>]. This string should remain
	///			simple for signal hash reasons.
	function toString(){
		return $"[U3DObject:{get_index()}]";
	}

	/// @desc	Frees up all data related to the object and makes the object 'unusable' from
	///			this point forward. Can be seen as the 'destructor' for the class. This should
	///			ALWAYS be called before delete <variable>.
	function free(){
		if (not U3DObject.get_is_valid_object(self))
			return;
		
		if (not is_undefined(hash)){	// If a manual free, force clean up the references
			// Since it is a manual free, attempt to remove references TO this instance:
			var ref_struct = self.get_data(["ref.other"]);
			var ref_keys = (is_undefined(ref_struct) ? [] : struct_get_names(ref_struct));
			for (var i = array_length(ref_keys) - 1; i >= 0; --i){
				var instance = ref_struct[$ ref_keys[i]];
				if (not U3DObject.get_is_valid_object(instance))
					instance.remove_child_ref(self);
			}
		
			struct_remove(U3D.MEMORY, hash);
			signaler.signal("cleanup");	// Throw a signal for any additional required cleanup
			hash = undefined;			// Wipe hash as it is now dereferenced
		}
			
		signaler.signal("free");
		signaler.clear();
		
		delete signaler;
		delete super;
		
		// Free references:
		var	data = self.get_data("ref");
		var instance_array = struct_get_values(data);
		for (var i = array_length(instance_array) - 1; i >= 0; --i){
			var instance = instance_array[i];
			self.remove_child_ref(instance);
		}
		
		is_freed = true;
	}
	#endregion
}