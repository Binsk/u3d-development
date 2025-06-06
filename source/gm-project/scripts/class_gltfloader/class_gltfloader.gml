/// @about
/// Handles loading GLTF data from disk into RAM as well as some basic 
/// data navigation and parsing. This structure only handles basic data loading
/// and parsing and does not handle converting data into U3D instances. For that
/// you need the GLTFBuilder().

/// @extensions
///	The following KHR extensions are FULLY supported:
///	-	N/A
///
/// The following KHR extensions are PARTIALLY supported:
/// -	KHR_lights_punctual
///			Only directional / point lights are supported
///
/// The following KHR extensions are IGNORED:
///	-	KHR_materials_*

/// @note	Ignored extensions will allow model building but may look incorrect.
///			Unsupported extensions will throw an exception.

/// @todo	Look into supporting KHR_draco_mesh_compression, but it seems to be a
///			complex Google library. Used fairly frequently with models, however,
///			and greatly reduces model file size.

/// @todo	Support `texCoord` property from Texture Info section to pull correct TEXCOORD_*
///			instead of assuming it is index 0.

function GLTFLoader() : U3DObject() constructor {
	#region PROPERTIES
	/// PREPROCESS_FUNCTION can be set to a function that takes a fixed buffer as an argument and
	/// returns a fixed buffer as a return. If set, the file buffer will be passed into this function
	/// and the returned buffer used for processing. This allows loading encrypted / specially formatted files
	/// as the function can handle converting from the special format back into glTF.
	static PREPROCESS_FUNCTION = undefined;
	
	gltf_version = undefined;
	binary_buffer_array = [];	// Array of GLTF buffers
	json_header = {};
	load_directory = undefined;	// Cached on a successful load for image loading
	#endregion
	
	#region STATIC METHODS
	/// @desc	Given a GLTF magic number representing a component type, converts it
	///			to the appropriate buffer component type. If invalid, undefined is returned.
	/// @param	{real}	component
	static get_buffer_ctype_from_gltf_ctype = function(component){
		if (component == 5120)
			return buffer_s8;
		if (component == 5121)
			return buffer_u8;
		if (component == 5122)
			return buffer_s16;
		if (component == 5123)
			return buffer_u16;
		if (component == 5125)
			return buffer_u32;
		if (component == 5126)
			return buffer_f32;
			
		return undefined;
	}
	
	/// @desc	Given a supported buffer component type, returns the number of bytes
	///			it takes up in memory.
	static get_buffer_ctype_byte_count = function(type){
		if (type == buffer_s8 or type == buffer_u8)
			return 1;
		if (type == buffer_s16 or type == buffer_u16)
			return 2;
		if (type == buffer_f32 or type == buffer_u32)
			return 4;
		
		return 0;
	}
	
	/// @desc	Given a gltf accessor type, as a string, returns the number of components
	///			required to represent it.
	static get_component_count_from_atype = function(type){
		if (type == "SCALAR")
			return 1;
		if (type == "VEC2")
			return 2;
		if (type == "VEC3")
			return 3;
		if (type == "VEC4")
			return 4;
		if (type == "MAT2")
			return 4;
		if (type == "MAT3")
			return 9;
		if (type == "MAT4")
			return 16;
		
		return 0;
	}
	
	/// @desc	Given a label and index, attempts to return the specified structure
	///			at the index under the specified label.
	/// @param	{real}		index	index of the array under the label
	/// @param	{string}	label	label to scan for values
	/// @return {json} or undefined
	function get_structure(index, label=""){
		if (is_undefined(json_header[$ label]))
			return undefined;
		
		if (index < 0)
			index = modwrap(index, array_length(json_header[$ label]));
		
		if (index >= array_length(json_header[$ label]))
			return undefined;
		
		return json_header[$ label][index];
	}
	
	/// @desc	Given a name and the label type, returns the structure with the
	///			matching name (or undefined).
	function get_structure_by_name(name, label=""){
		if (is_undefined(json_header[$ label]))
			return undefined;
		
		var array = json_header[$ label];
		for (var i = array_length(array) - 1; i >= 0; --i){
			if ((array[i][$ "name"] ?? "") == name)
				return array[i];
		}
		
		return undefined;
	}
	
	/// @desc	Given the structure's name and label type, returns the index it is
	///			found at (or -1 if not found)
	function get_structure_index(name, label=""){
		if (is_undefined(json_header[$ label]))
			return -1;
		
		var array = json_header[$ label];
		for (var i = array_length(array) - 1; i >= 0; --i){
			if ((array[i][$ "name"] ?? "") == name)
				return i;
		}
		
		return -1;
	}
	
	/// @desc	Returns an array of extension names specified as used in this model that
	///			may be able to be ignored.
	function get_extensions_used(){
		return json_header[$ "extensionsUsed"] ?? [];
	}
	
	
	/// @desc	Returns an array of extension names specified that MUST be supported to
	///			load this model.
	function get_extensions_required(){
		return json_header[$ "extensionsRequired"] ?? [];
	}
	
	/// @desc	Returns if the specified extension name is implemented by this loader.
	function get_is_extension_implemented(name){
		static EXTENSIONS = {
			"KHR_lights_punctual" : 			true,
			"KHR_draco_mesh_compression" :		false,		// Want to implement (requires research on complexity)
			"KHR_materials_ior" :				false,		// Will likely implement (Requires in-shader IOR conversion)
			"KHR_materials_specular" :			false,		// May implement (requires extra RGB buffer)
			"KHR_materials_unlit" : 			false,		// Will NOT implement (export material as emissive instead)
			"KHR_materials_transmission" :		false,		// Want to implement (would handle proper reflections on translucent materials)
			"KHR_materials_emissive_strength" :	false,		// Will implement
			"KHR_collision_shapes" :			false,		// Want to implement (requires research on complexity; it is still under review by Khronos)
			"KHR_texture_transform" :			false,		// Want to implement (requires in-house texture atlas system)
		}
		
		return EXTENSIONS[$ name] ?? false;
	}
	
	/// @desc	Returns if the specified extension can be ignored by this loader and still
	///			load successfully.
	function get_is_extension_ignoreable(name){
		return string_starts_with(name, "KHR_materials_"); // Materials can be ignored, they render incorrectly but otherwise still load
	}
	
	/// @desc	Returns if the specified extenion is specified in the model.
	///			Returns 0 if false, 1 if included, 2 if required
	function get_has_extension(name){
		if (array_get_index(get_extensions_required(), name) >= 0)
			return 2;
		
		if (array_get_index(get_extensions_used(), name) >= 0)
			return 1;
		
		return 0;
	}
	#endregion
	
	#region METHODS
	/// @desc	Attempts to load a GLTF model from the disk; supports both
	///			binary and text data.
	///	@note	Only supports version 2 of the spec (the only version at the time of this implementation)
	/// @param	{string}	name		file name + extension of the file to load
	/// @param	{string}	directory	directory the model file is located in
	function load(name="", directory=""){
		if (not string_ends_with(directory, "/") and not string_ends_with(directory, "\\") and directory != "")
			directory += "/";
		
		if (not file_exists(directory + name)){
			ExceptionGLTF.throw_conditional(string_ext("file does not exist [{0}{1}]!", [directory, name]), EXCEPTION_GLTF.missing_file);
			return false;
		}
		
		self.free(true);	// Wipe and free up all old data
		load_directory = directory;
		
		#region IMPORT FUNC
		/// An internal function to import buffers off of the disk that are not
		/// included in the base file. Returns if successful.
		function import_buffers(directory){
			if (is_undefined(json_header[$ "buffers"]))
				return false; // No buffer array
				
			var buffer_array = json_header.buffers;
			for (var i = 0; i < array_length(buffer_array); ++i){
				var buffer_json = buffer_array[i];
				// If no URI, the buffer is already loaded
				if (is_undefined(buffer_json[$ "uri"]))
					continue;
				
				// Calculate relative path to primary file
				var path = directory + buffer_json.uri;
				if (not file_exists(path))
					throw new ExceptionGLTF(string_ext("missing buffer [{0}]", [path]), EXCEPTION_GLTF.missing_file);
				
				var buffer = buffer_load(path);
				array_push(binary_buffer_array, buffer);
			}
			
			return true;
		}
		#endregion
		
		var buffer = undefined;
		// Read in initial data:
		buffer = buffer_load(directory + name);
		
		if (not is_undefined(PREPROCESS_FUNCTION)){
			var b = buffer;
			buffer = PREPROCESS_FUNCTION(b);
			buffer_delete(b);
		}
		
		buffer_seek(buffer, buffer_seek_start, 0);
		
		// Check magic bytes to determine if gltf instead of glb:
		#region READ NON-BINARY
		if (buffer_read(buffer, buffer_u32) != 1179937895){ // glTF
			// Non-binary; load things in as JSON
			buffer_seek(buffer, buffer_seek_start, 0);
			var json_string = buffer_read(buffer, buffer_text);
			var json = json_parse(json_string);
			if (is_undefined(json[$ "asset"]))
				throw new ExceptionGLTF("invalid gltf file!", EXCEPTION_GLTF.invalid_file);
			
			gltf_version = real(json.asset[$ "version"] ?? 0);
			if (gltf_version != 2)
				throw new ExceptionGLTF(string_ext("unsupported glTF version[{0}]", [gltf_version]), EXCEPTION_GLTF.invalid_file);
			
			buffer_delete(buffer);
			buffer = undefined;
			
			json_header = json;
			
			var success = false;
			try{
				success = self.import_buffers(directory);
				if (not success)
					self.free();
			}
			catch(e){
				self.free();
				throw e;
			}
				
			var required_extensions = self.get_extensions_required();
			for (var i = array_length(required_extensions) - 1; i >= 0; --i){
				if (not self.get_is_extension_implemented(required_extensions[i]))
					throw new ExceptionGLTF($"model uses unsupported extension, [{required_extensions[i]}]", EXCEPTION_GLTF.unsupported_feature);
			}
				
			return success;
		}
		#endregion
		
		#region READ BINARY
		// At this point, we know the system is binary so treat it as such
		gltf_version = buffer_read(buffer, buffer_u32);
		if (gltf_version != 2)
			throw new ExceptionGLTF(string_ext("unsupported glTF version[{0}]", [gltf_version]), EXCEPTION_GLTF.invalid_file);	
			
		var data_length = buffer_read(buffer, buffer_u32); // Data left in the file; excluding the header
		var json = {};
		// GLTF will have betweet 1 and 2 chunks. Chunk 1 is ALWAYS JSON (but we parse dynamically, anyway) and
		// Chunk 2 will either be nothing or a binary chunk. Other binary chunks may be external files that
		// will be loaded!
		for (var i = 0; i < 2; ++i){
			if (buffer_tell(buffer) >= data_length) // End of file
				break;
			
			var chunk_length = buffer_read(buffer, buffer_u32);
			var chunk_type = buffer_read(buffer, buffer_u32);
			var end_tell = buffer_tell(buffer) + chunk_length;
			if (chunk_type == 1313821514){ // Magic: JSON
				var buffer_json = buffer_create(chunk_length, buffer_fixed, 1);
				buffer_copy(buffer, buffer_tell(buffer), chunk_length, buffer_json, 0);
				buffer_seek(buffer_json, buffer_seek_start, 0);
				var json_string = buffer_read(buffer_json, buffer_text);
				buffer_delete(buffer_json);
				
				json = json_parse(json_string);
				buffer_seek(buffer, buffer_seek_start, end_tell);
			}
			else if (chunk_type == 5130562){ // Magic: BIN
				 var buffer_bin = buffer_create(chunk_length, buffer_fixed, 1);
				 buffer_copy(buffer, buffer_tell(buffer), chunk_length, buffer_bin, 0);
				 array_push(binary_buffer_array, buffer_bin);
				 buffer_seek(buffer, buffer_seek_start, end_tell);
			}
		}
		buffer_delete(buffer);
		buffer = undefined;
		#endregion

		json_header = json;
		var success = false;
		try{
			success = self.import_buffers(directory);

			if (not success)
				self.free();
		}
		catch (e){
			self.free();
			throw e;
		}
		
		var required_extensions = self.get_extensions_required();
		for (var i = array_length(required_extensions) - 1; i >= 0; --i){
			if (not self.get_is_extension_implemented(required_extensions[i]))
				throw new ExceptionGLTF($"model uses unsupported extension, [{required_extensions[i]}]", EXCEPTION_GLTF.unsupported_feature);
		}
			
		return success;
	}
	
	/// @desc	Given a struct, checks for the 'extras' section and whether or
	///			not it requires an unsupported extension. If it is unsupported an exception
	///			is thrown immediately.
	function check_unsupported_extensions(header_data){
		if (not is_struct(header_data))
			return;
		
		if (is_undefined(header_data[$ "extensions"]))
			return;
		
		var keys = struct_get_names(header_data.extensions);
		for (var i = array_length(keys) - 1; i >= 0; --i){
			if (not self.get_is_extension_implemented(keys[i])){
				if (not self.get_is_extension_ignoreable(keys[i]))
					throw new ExceptionGLTF($"model uses unsupported extension, [{keys[i]}]", EXCEPTION_GLTF.unsupported_feature);
				else
					print_traced("WARNING", $"ignoring unsupported glTF extension [{keys[i]}]");
			}
		}
	}
	
	/// @desc	Given the image index, attempts to import it from the disk and 
	///			generate a sprite from it. Returns undefined if there was an issue.
	///			Note that the sprite will not be automatically freed and will need to
	///			be deleted when no longer needed.
	function generate_sprite(index){
		var image = self.get_structure(index, "images");
		if (is_undefined(image)) // Invalid index
			return undefined;
		
		var sprite = undefined;
		// External image file:
		if (not is_undefined(image[$ "uri"])){
			if (not file_exists(load_directory + image.uri))
				throw new ExceptionGLTF(string_ext("file not found [{0}]", [load_directory + image.uri]), EXCEPTION_GLTF.missing_file);
			
			sprite = sprite_add(load_directory + image.uri, 1, false, false, 0, 0);
		}
		// Included buffer data:
		else{
			if (string_lower(image.mimeType) != "image/png" and string_lower(image.mimeType) != "image/jpeg")
				throw new ExceptionGLTF(string_ext("unsupported mime type [{0}]", [image.mimeType]), EXCEPTION_GLTF.unsupported_feature);
			
			var buffer = self.read_buffer_view(image.bufferView);
			if (is_undefined(buffer))
				throw new ExceptionGLTF("invalid image bufferView!", EXCEPTION_GLTF.invalid_file);
			
			// We can't read PNG/JPG straight from the buffer unless we have our own parser; and
			// that isn't worth writing. Re-save to disk as image file and load that in through
			// GameMaker's functions.
			buffer_save_ext(buffer, "__import", 0, buffer_get_size(buffer));
			sprite = sprite_add("__import", 1, false, false, 0, 0);
			
			file_delete("__import");
			buffer_delete(buffer);
		}		
		
		return sprite;
	}
	
	/// @desc	Given a buffer view index, generates a new buffer containing the relevant data.
	///			The returned buffer must be manually destroyed. If there is an issue, undefined
	///			is returned.
	function read_buffer_view(index){
		var buffer_view = self.get_structure(index, "bufferViews");
		if (is_undefined(buffer_view))
			return undefined;
		
		var buffer_index = buffer_view.buffer;
		var buffer_offset = (is_undefined(buffer_view[$ "byteOffset"]) ? 0 : buffer_view.byteOffset);
		var buffer_length = buffer_view.byteLength;
		var buffer = binary_buffer_array[buffer_index];
		var nbuffer = buffer_create(buffer_length, buffer_fixed, 1);
		buffer_copy(buffer, buffer_offset, buffer_length, nbuffer, 0);
		return nbuffer;
	}
	
	/// @desc	Given an accessor index, attempts to read the data specified inside.
	///			The relevant datatype will be returned based on the accessor type or, 
	///			if no special datatype exists, an array of values. MAT3s will be converted
	///			to MAT4s
	/// @note	Does NOT support sparse accessors!
	/// @param	{real}	index		index of the accessor to read data from
	///	@param	{bool}	skip_parse	if true datatype parsing is skipped and only arrays are retruned (faster)
	/// @note	If parsing is skipped, MAT3 is NOT converted and the array returned is a 1D array!
	function read_accessor(index, skip_parse=false){
		var accessor = self.get_structure(index, "accessors");
		if (is_undefined(accessor))
			return undefined;
		
		var data_type = get_buffer_ctype_from_gltf_ctype(accessor.componentType); // What kind of data components we are pulling
		var element_size = get_component_count_from_atype(accessor.type); // How many components per element
		var element_count = accessor.count;	// How many elements we are reading
		var data = [];
		
		if (is_undefined(accessor[$ "bufferView"])){
/// @todo	Implement sparse accessors
			if (not is_undefined(accessor[$ "sparse"]))
				throw new ExceptionGLTF("sparse accessors are not currently supported!", EXCEPTION_GLTF.unsupported_feature);
				
			// Per the spec, fill components w/ zeros
			data = array_create(element_count * element_size, 0);
		}
		else {
			var buffer = self.read_buffer_view(accessor.bufferView);
			if (is_undefined(buffer)) // Invalid buffer
				throw new ExceptionGLTF("accessor accessing invalid bufferView!", EXCEPTION_GLTF.invalid_file);
			
			buffer_seek(buffer, buffer_seek_start, accessor[$ "byteOffset"] ?? 0);
			data = buffer_read_series(buffer, data_type, element_count * element_size);
			buffer_delete(buffer);
		}
		
		// Limit to min/max:
		var maximum = accessor[$ "max"] ?? array_create(element_size, infinity);
		var minimum = accessor[$ "min"] ?? array_create(element_size, -infinity);
		for (var i = 0; i < element_count; ++i){
			index = element_size * i;
			for (var j = 0; j < element_size; ++j)
				data[index + j] = clamp(data[index + j], minimum[j], maximum[j]);
		}
		
		if (skip_parse)
			return data;
		
		// Parse data into types
		var array = array_create(element_count, undefined);
		for (var i = 0; i < element_count; ++i){
			index = i * element_size;
			if (element_size == 1)		// Scalar
				array[i] = data[index];
			else if (element_size == 2)	// Vec2 (we just use an array)
				array[i] = [data[index], data[index + 1]];
			else if (element_size == 3) // Vec3
				array[i] = vec(data[index], data[index + 1], data[index + 2]);
			else if (element_size == 4) // Could also be a MAT2/VEC4, but we use a QUAT for storage
				array[i] = quat(data[index], data[index + 1], data[index + 2], data[index + 3]);
			else if (element_size == 9){	// MAT3, we convert to MAT4
				var subarray = matrix_build_identity();
				for (var j = 0; j < 3; ++j){
					subarray[j] = data[index + j];
					subarray[j + 4] = data[index + j + 4];
					subarray[j + 8] = data[index + j + 8];
				}
				array[i] = subarray;
			}
			else if (element_size == 16){ // MAT4
				var subarray = matrix_build_identity();
				for (var j = 0; j < 16; ++j)
					subarray[j] = data[index + j];
				
				array[i] = subarray;
			}
		}
		
		return array;
	}
	
	super.register("free");
	function free(ignore_super=false){
		for (var i = array_length(binary_buffer_array) - 1; i >= 0; --i)
			buffer_delete(binary_buffer_array[i]);
		
		binary_buffer_array = [];
		gltf_version = undefined;
		json_header = {};
		load_directory = undefined;
		
		if (not ignore_super)
			super.execute("free");
	}
	#endregion
}

// Define special exception data and info for loading glTF files:
enum EXCEPTION_GLTF {
	unknown,				// Unrecognized / unclassified exception
	invalid_arg,			// Invalid argument was passed
	invalid_file,			// Improperly formatted model file
	missing_file,			// File doesn't exist
	unsupported_feature,	// Model file has unsupported features that cannot be ignored
}

function ExceptionGLTF(message=undefined, index=EXCEPTION_GLTF.unknown) : Exception(message, index) constructor {
	#region PROPERTIES
	self.message = "[glTF] " + string(message);
	path = "";
	#endregion
	
	#region STATIC METHODS
	static throw_conditional = function(message, index=0){
		Exception.throw_conditional(message, index, ExceptionGLTF, 1);
	}
	#endregion
	
	#region METHODS
	/// @desc	Return the file path that was being loaded when the exception occurred.
	function get_file(){
		return path;
	}
	#endregion
	
	#region INIT
	self._update_message(2);
	
	if (is_instanceof(other, GLTFLoader)){
		var directory = other.load_directory;
		if (not string_ends_with(directory, "/") and not string_ends_with(directory, "\\") and directory != "")
			directory += "/";
			
		path = directory + (other[$ "name"] ?? "");
	}
	#endregion
}