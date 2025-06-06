/// @about
/// To simplify GLTF model loading w/ dynamic vertex format types, this provides
/// a way to store a raw vertex format as well as its defining order. A VertexFormat
/// should NOT be created via 'new' keyword! Create a new format via the static function
/// VertexFormat.get_format_instance(). While it is fine creating via 'new' this will
/// create duplicates behind-the scenes where `get_format_instance` will re-use existing
/// formats.

/// @desc	The VERTEX_DATA enum contains possible format attributes for the built-in
/// 		rendering system. 
enum VERTEX_DATA {
	position,		// 3D position
	color,			// Color / Alpha pair
	texture,		// UV texture coordinate
	normal,			// 3D normal
	tangent,		// 3D normal tangent
	bone_indices,	// 4D bone indices
	bone_weights,	// 4D bone weights
};

/// @desc	Creates a new vertex format and stores the vertex definition order.
/// @param	{array}	vformat_array	Array of VERTEX_DATA values specifying the data to be stored in the format
function VertexFormat(vformat_array=[VERTEX_DATA.position, VERTEX_DATA.texture]) : U3DObject() constructor {
	#region PROPERTIES
	static FORMAT_MAP = {};	// Used to cache similar formats to help prevent duplication
	
	vformat = undefined;
	self.vformat_array = [];
	byte_count = 0;
	#endregion
	
	#region STATIC METHODS
	/// @desc	Returns the VertexFormat that matches the specified array specification.
	///			If one doesn't exist it will be generated and returned.
	static get_format_instance = function(vformat_array=[]){
		var hash = md5_string_utf8(string(vformat_array));
		return VertexFormat.FORMAT_MAP[$ hash] ?? new VertexFormat(vformat_array);
	}
	
	/// @desc	Given a VERTEX_DATA value, returns the glTF look-up label
	static get_vertex_data_gltf_label = function(value){
		static LABELS = [
			"POSITION",
			"COLOR_0",		// Only support 1 vertex color!
			"TEXCOORD_0",	// Only support 1 texture!
			"NORMAL",
			"TANGENT",
			"JOINTS_0",
			"WEIGHTS_0"
		];
		
		if (value < 0)
			return undefined;
		if (value >= array_length(LABELS))
			return undefined;
		
		return LABELS[value];
	}
	
	/// @desc	Given a VERTEX_DATA value, returns a default value for an 'undefined' element
	static get_vertex_data_default = function(value){
		static DEFAULTS = [
			vec(),
			quat(1, 1, 1, 1),	// rgba; this due to glTF loading style
			[0, 0],
			vec(0, 0, 1),
			vec(),
			quat(-1, -1, -1, -1), // <0 will be ignored in the shader
			quat()
		];
		
		if (value < 0)
			return undefined;
		if (value >= array_length(DEFAULTS))
		
			return undefined;
		return DEFAULTS[value];
	}
	#endregion
	
	#region METHODS
	/// @desc	returns the actual GameMaker vertex format stored within the class.
	function get_format(){
		return vformat;
	}
	
	/// @desc	Returns if this format has the specified kind of vertex data.
	/// @param	{VERTEX_DATA}	value
	function get_has_data(value){
		for (var i = array_length(vformat_array) - 1; i >= 0; --i){
			if (vformat_array[i] == value)
				return true;
		}
		return false;
	}
	
	function toString(){
		return string(self.get_format());
	}
	
	/// @desc	Returns the number of bytes required for a single vertex with this format
	function get_byte_count(){
		return byte_count;
	}
	
	/// @desc	Returns the format look-up hash. This is NOT the same as the U3DObject
	///			referencing hash.
	function get_hash(){
		return md5_string_utf8(string(vformat_array));
	}
	
	super.register("free");
	function free(){
		struct_remove(FORMAT_MAP, self.get_hash());
		vertex_format_delete(vformat);
		super.execute("free");
	}
	#endregion
	
	#region INIT
	if (array_length(vformat_array) <= 0) // Provided vertex format data is empty
		throw new Exception("Invalid vertex format size [0]");
	
	// Re-order format as the glTF loader requires certian elements fully defined
	// before others (such as UV / Position to auto-calculate tangents)
	var priority = ds_priority_create();
	for (var i = array_length(vformat_array) - 1; i >= 0; --i)
		ds_priority_add(priority, vformat_array[i], vformat_array[i]);
	
	vformat_array = [];
	while (not ds_priority_empty(priority))
		array_push(vformat_array, ds_priority_delete_min(priority));
	
	ds_priority_destroy(priority);
	
	// Create actual vertex format:
	vertex_format_begin();
	for (var i = 0; i < array_length(vformat_array); ++i){
		switch (vformat_array[i]){
			case VERTEX_DATA.position:
				vertex_format_add_position_3d();
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 12;
				break;
			case VERTEX_DATA.color:
				vertex_format_add_color();
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 4;
				break;
			case VERTEX_DATA.texture:
				vertex_format_add_texcoord();
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 8;
				break;
			case VERTEX_DATA.normal:
				vertex_format_add_normal();
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 12;
				break;
			case VERTEX_DATA.tangent:
				vertex_format_add_custom(vertex_type_float3, vertex_usage_texcoord);
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 12;
				break;
			case VERTEX_DATA.bone_indices:
				vertex_format_add_custom(vertex_type_float4, vertex_usage_texcoord);
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 16;
				break;
			case VERTEX_DATA.bone_weights:
				vertex_format_add_custom(vertex_type_float4, vertex_usage_texcoord);
				array_push(self.vformat_array, vformat_array[i]);
				byte_count += 16;
				break;
		}
	}
	
	if (array_length(self.vformat_array) <= 0) // Processed vertex format data is empty
		throw new Exception("unexpected final vertex format size [0]");
	
	vformat = vertex_format_end();
	
	FORMAT_MAP[$ self.get_hash()] = self; // Note, will overwrite anything already cached
	#endregion
}