/// @about
/// A primitive defines a single generalized 3D shape. Renderable 3D elements in-game
/// often consist of multiple primitives put together.
///
/// When defining the vertex buffer, each element can be added separate as long as
/// the vertex index they belong to is in order. Once the definition ends, the final 
/// buffer will be stitched together in the order specified by the vertex format.

/// @desc	Create a new empty Primitive that can be defined and passed around
///			to numerous Mesh instances.
/// @param   {VertexFormat}	vformat	The special VertexFormat that defines what data
/// 									   will be used in the Primitive.
function Primitive(vformat) : U3DObject() constructor {
	#region PROPERTIES
	self.vformat = vformat;
	self.vbuffer = undefined;
	is_frozen = false;
	#endregion

	#region METHODS
	function get_is_frozen(){
		return is_frozen;
	}
	
	function get_triangle_count(){
		if (is_undefined(vbuffer))
			return 0;
		
		return vertex_get_number(vbuffer) / 3;
	}
	
	function get_has_bones(){
		return	array_get_index(vformat.vformat_array, VERTEX_DATA.bone_indices) >= 0 or
				array_get_index(vformat.vformat_array, VERTEX_DATA.bone_weights) >= 0
	}
	
	/// @desc	Begins defining the vertex buffer for this primitive. Note that ALL primitives
	///			should be defined in the pr_trianglelist format.
	function define_begin(size=0){
		if (not is_undefined(self[$ "definition_data"]))
			throw new Exception("cannot start new [Primitive] definition; definition already in progress!");
		
		definition_data = {};
		if (not is_undefined(vbuffer)){
			vertex_delete_buffer(vbuffer);
			vbuffer = undefined;
		}
		
		for (var i = array_length(vformat.vformat_array) - 1; i >= 0; --i)
			definition_data[$ vformat.vformat_array[i]] = array_create(size, undefined);
		
		is_frozen = false;
	}
	
	/// @desc	Returns an already defined piece of data from the primitive's definition.
	///			This is only valid while the definition is occurring. Returns undefined if
	///			there is a problem.
	function define_get_data(type=VERTEX_DATA.position, index=0){
		if (is_undefined(self[$ "definition_data"])) // Not defining
			return undefined;
			
		if (not vformat.get_has_data(type))	// Doesn't have the property
			return undefined;
			
			// Index out-of-bounds:
		if (index < 0 or index >= array_length(definition_data[$ type] ?? []))
			return undefined;
			
		return definition_data[$ type][index];
	}
	
	/// @desc	Short-hand for define_set_data(-1, ...).
	function define_add_data(type=VERTEX_DATA.position, data=[]){
		define_set_data(-1, type, data);
	}
	
	/// @desc	Sets a piece of data in the vertex definition at the specified vertex index
	///			starting at 0. If -1 is specified, it will be added to the end of the list.
	///			The data provided should match the VERTEX_DATA type. See the switch/case for
	///			valid types per VERTEX_DATA type.
	function define_set_data(index=-1, type=VERTEX_DATA.position, data=[]){
		if (is_undefined(self[$ "definition_data"]))
			throw new Exception("cannot add vertex data; no buffer defined.");
			
		var array = (definition_data[$ type] ?? []);
		if (index < 0){
			index = definition_data[$ $"{type}_index"] ?? 0;
			definition_data[$ $"{type}_index"] = index + 1;
		}
		else
			definition_data[$ $"{type}_index"] = max(definition_data[$ $"{type}_index"] ?? 0, index);
			
		switch (type){
			// Define as vec, array[vec] >= 1, or array[real] >= 3
			case VERTEX_DATA.position:
			case VERTEX_DATA.normal:
			case VERTEX_DATA.tangent:
				if (is_vec(data))
					data = vec_to_array(data);
				else if (is_array(data) and array_length(data) > 0){
					if (is_vec(data[0]))
						data = vec_to_array(data[0]);
					else if (array_length(data) < 3)
						throw new Exception("data does not match type!");
				}
				else 
					throw new Exception("data does not match type!");

				array[index] = array_duplicate_shallow(data, 0, 3);
			break;
			
			// Define as array[real] >= 2, quat (r,g,b,a), vec(r, g, b)
			case VERTEX_DATA.color:
				if (is_quat(data)){
					array[index] = [vec_to_color(data), data.w];
					break;
				}
				else if (is_vec(data)){
					array[index] = [vec_to_color(data), 1.0];
					break;
				}
			
			// Define as array[real] >= 2
			case VERTEX_DATA.texture:
				if (not is_array(data) or array_length(data) < 2)
					throw new Exception("data does not match type!");
				
				array[index] = array_duplicate_shallow(data, 0, 2);
			break;
			
			// Define as quat, array[quat] >= 1, or array[real] >= 4
			case VERTEX_DATA.bone_indices:
			case VERTEX_DATA.bone_weights:
				if (is_quat(data))
					data = quat_to_array(data);
				else if (is_array(data) and array_length(data) > 0){
					if (is_quat(data[0]))
						data = quat_to_array(data[0]);
					else if (array_length(data) < 4)
						throw new Exception("data does not match type!");
				}
				else 
					throw new Exception("data does not match type!");
				
				array[index] = array_duplicate_shallow(data, 0, 4);
			break;
			
			default:
				throw new Exception("invalid type!");
		}
		
		definition_data[$ type] = array;
	}
	
	/// @desc	Sets a piece of data in the specified index. Does NOT do any error
	///			checking and expects specific arrays of data for each type. This function
	///			exists if you know exactly what you are defining as it is faster than
	///			using the regular add/set functions.
	function define_set_data_raw(index, type, data, set_index=false){
		var array = definition_data[$ type];
		array[index] = data;
		definition_data[$ type] = array;
		if (set_index)
			definition_data[$ $"{type}_index"] = max(definition_data[$ $"{type}_index"] ?? 0, index + 1);
	}
	
	/// @desc	Ends the primitive definition and builds the appropriate vertex buffer
	function define_end(){
		if (is_undefined(self[$ "definition_data"]))
			throw new Exception("cannot build vertex data; no buffer defined.");
			
		var vertex_count = -1;
		// Verify the data is valid:
		for (var i = array_length(vformat.vformat_array) - 1; i >= 0; --i){
			var array = definition_data[$ vformat.vformat_array[i]];
			if (not is_array(array))
				throw new Exception("cannot build vertex buffer, type undefined.");
			
			if (definition_data[$ $"{vformat.vformat_array[i]}_index"] != vertex_count and vertex_count >= 0)
				throw new Exception(string_ext("type count miss-match in vertex buffer [{0} != {1}]", [vertex_count, array_length(array)]));
				
			vertex_count = definition_data[$ $"{vformat.vformat_array[i]}_index"];
			
			// Loop through values, make sure there aren't any undefined slots
			for (var j = definition_data[$ $"{vformat.vformat_array[i]}_index"] - 1; j >= 0; --j){
				if (is_undefined(array[j]))
					throw new Exception("type contains undefined vertex values.");
			}
		}
		
		// Make sure we have > 0 vertices:
		if (vertex_count <= 0)
			throw new Exception("cannot define vertex buffer with < 1 vertices!");
		
		// Build actual vertex buffer:
		if (not is_undefined(vbuffer))
			vertex_delete_buffer(vbuffer);
		
		var format_components = array_length(vformat.vformat_array);
		vbuffer = vertex_create_buffer_ext(vformat.get_byte_count() * vertex_count);
		vertex_begin(vbuffer, vformat.vformat);
		for (var i = 0; i < vertex_count; ++i){
			for (var j = 0; j < format_components; ++j){
				var format = vformat.vformat_array[j];
				var data = definition_data[$ format][i];
				switch (format){
					case VERTEX_DATA.position:
						vertex_position_3d(vbuffer, data[0], data[1], data[2]);
						break;
					case VERTEX_DATA.color:
						vertex_color(vbuffer, data[0], data[1]);
						break;
					case VERTEX_DATA.texture:
						vertex_texcoord(vbuffer, data[0], data[1]);
						break;
					case VERTEX_DATA.normal:
						vertex_normal(vbuffer, data[0], data[1], data[2]);
						break;
					case VERTEX_DATA.tangent:
						vertex_float3(vbuffer, data[0], data[1], data[2]);
						break;
					case VERTEX_DATA.bone_indices:
					case VERTEX_DATA.bone_weights:
						vertex_float4(vbuffer, data[0], data[1], data[2], data[3]);
						break;
				}
			}
		}
		vertex_end(vbuffer);
		
		// Remove temporary structure:
		struct_remove(self, "definition_data");
	}
	
	/// @desc	Freezes the vertex buffer into vRAM. This means it will take up
	///			vRAM from now onwards but will also be SIGNIFICANTLY faster to render.
	///			Returns if successful.
	function define_freeze(){
		if (not is_undefined(self[$ "definition_data"]))
			throw new Exception("cannot freeze buffer; data not fully defined!");
			
		if (is_undefined(vbuffer))
			return false;
		
		if (is_frozen)
			return true;
		
		is_frozen = true;
		return (vertex_freeze(vbuffer) >= 0);
	}

	super.register("free");
	function free(){
		super.execute("free");
		
		if (not is_undefined(vbuffer)){
			vertex_delete_buffer(vbuffer);
			vbuffer = undefined;
		}
	}
	#endregion
	
	#region INIT
	if (not is_instanceof(vformat, VertexFormat))
		throw new Exception("invalid vertex format, expected type [VertexFormat]!");
	#endregion
}