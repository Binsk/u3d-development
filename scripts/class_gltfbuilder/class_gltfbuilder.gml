/// @about
/// The GLTFBuilder is an extension of the GLTFLoader that provides functions for
/// constructing in-game meshes, materials, and the like out of the buffer data
/// contained within. Unless you are doing something very specific or custom, 
/// you should load in GLTF / GLB files with this rather than the GLTFLoader().
///
/// All structures generated by the builder must be MANUALLY freed and destroyed,
/// otherwise it will cause a memory leak.
///
/// @note	The GLTFBuilder does NOT support the full glTF spec and all of its
///			nuances. It was designed to handle general-case usage of Blender exports.

function GLTFBuilder(name="", directory="") : GLTFLoader() constructor {
	#region PROPERTIES
	self.directory = directory;
	#endregion
	
	#region METHODS
	/// @desc	Returns the total number of meshes in the loaded model.
	function get_mesh_count(){
		return array_length(json_header[$ "meshes"] ?? []);
	}
	
	/// @desc	Given a mesh index in the file, returns the number of primitives
	///			required to define the mesh.
	function get_primitive_count(mesh_index){
		if (not in_range(mesh_index, 0, get_mesh_count() - 1)) // Invalid mesh
			return 0;
		
		return array_length(json_header.meshes[mesh_index][$ "primitives"] ?? []);
	}
	
	/// @desc	Given a primitive, generates a VertexFormat that will correctly
	///			contain all the data specified by the model file.
	function get_primitive_format(mesh_index, primitive_index){
/// @stub implement
	}
	
	/// @desc	Generates an array of spatial materials. Note that the materials
	///			will have dynamically-generated sprites attached to them that will
	///			be automatically freed upon material free, thus invalidating the
	///			attached texture!
	function generate_material_array(){
		var material_data_array = json_header[$ "materials"];
		var material_array = array_create(array_length(material_data_array), undefined);
		var sprite_data_array = json_header[$ "images"];
		var sprite_array = array_create(array_length(sprite_data_array), undefined); // Contains generated sprites
		
		// First add new sprites to the system:
		for (var i = 0; i < array_length(sprite_data_array); ++i){
			var data = sprite_data_array[i];
			var sprite;
			if (not is_undefined(data[$ "uri"])){ // External file, load normally
				if (not file_exists(directory + data.uri)){
					Exception.throw_conditional(string_ext("failed to find image [{0}].", [directory + data.uri]));
					continue;
				}
				
				sprite = sprite_add(directory + data.uri, 0, false, false, 0, 0);
				if (sprite < 0)
					throw new Exception(string_ext("failed to add sprite [{0}]!", [directory + data.uri]));
					
				sprite_array[i] = sprite;
				continue;
			}
			
			// Data buffer, must write to disk to re-load as PNG
			if (string_lower(data.mimeType) != "image/png" and string_lower(data.mimeType) != "image/jpeg"){
				Exception.throw_conditional(string_ext("unsupported mime type [{0}].", [data.mimeType]));
				continue;
			}
			
			var buffer = read_buffer_view(json_header.bufferViews[data.bufferView]);
			if (is_undefined(buffer)){
				Exception.throw_conditional(string_ext("failed to read buffer view [{0}].", [data.bufferView]));
				continue;
			}
			
			var ext = string_delete(data.mimeType, 1, 6);
			buffer_save(buffer, "__import." + ext);
			sprite = sprite_add("__import." + ext, 0, false, false, 0, 0);
			
			if (sprite < 0){
				buffer_delete(buffer);
				file_delete("__import." + ext);
				
				Exception.throw_conditional("failed to add sprite from buffer!");
				continue;
			}
			
			sprite_array[i] = sprite;
	
			buffer_delete(buffer);
			file_delete("__import." + ext);
		}
		
		// Next generate the material data:
		for (var i = 0; i < array_length(material_data_array); ++i){
			var material_data = material_data_array[i];
			var pbr_data = material_data[$ "pbrMetallicRoughness"]; // May not be set!
			// First, a quick check to see if we failed to load the sprite and fill w/ 'no texture'
			if (not is_undefined(pbr_data) and not is_undefined(pbr_data[$ "baseColorTexture"]) and is_undefined(sprite_array[pbr_data[$ "baseColorTexture"]])){
				material_array[i] = U3D.RENDERING.MATERIAL.missing_texture.duplicate();
				continue;
			}
			
			// Defaults:
			var color_base = [1, 1, 1, 1];
			var color_sprite = undefined;
			
			if (not is_undefined(pbr_data)){
				color_base = pbr_data[$ "baseColorFactor"] ?? color_base;
				if (not is_undefined(pbr_data[$ "baseColorTexture"])){
/// @stub	Add support for pulling the texture UV index?
					var texture_index = get_structure(pbr_data[$ "baseColorTexture"].index, "textures").source;
					color_sprite = sprite_array[texture_index];
				}
/// @stub	Implement metallic, etc
			}
			
			var material = new MaterialSpatial();
			if (not is_undefined(color_sprite))
				material.set_texture("albedo", sprite_get_texture(color_sprite, 0));
				
			material.scalar.albedo = color_base;
			
			// Attach free method to free up sprites as needed:
			material.signaler.add_signal("free", new Callable(material, function(albedo){
				if (not is_undefined(color_sprite))
					sprite_delete(color_sprite);
			}, [color_sprite]))
			
			material_array[i] = material;
		}
		
		return material_array;
	}
	
	/// @desc	Given a mesh and primitive index, attempts to generate a Primitive.
	///			The Primitive will contain the properties specified according to the 
	///			specified format. If the format contains values that are undefined by the
	///			model, the system will attempt to generate them (if possible) or fill them
	///			with 0 values. Returns 'undefined' if an error occurred.
	/// @param	{int}	mesh_index				index of the mesh to read from
	/// @param	{int}	primitive_index			index of the primitive to generate
	/// @param	{VertexFormat} vertex_format	vertex format to specify data layout and inclusion
	/// @param	{int}	transform=undefined		transform matrix to apply to each vertex position
	function generate_primitive(mesh_index, primitive_index, format, transform=undefined) {
		if (not in_range(mesh_index, 0, get_mesh_count() - 1))	// Invalid mesh index
			return undefined;
		
		if (not in_range(primitive_index, 0, get_primitive_count(mesh_index) - 1)) // Invalid primitive index
			return undefined;
		
		if (not is_instanceof(format, VertexFormat)){
			Exception.throw_conditional("invalid type, expected [VertexFormat]!");
			return undefined;
		}
		
		// Fetch our primitive header so we know what data we have:
		var primitive_header = json_header.meshes[mesh_index].primitives[primitive_index];
			// Check topology, we only support one type of many:
		if ((primitive_header[$ "mode"] ?? 4) != 4){
			var mode_labels = ["POINTS", "LINES", "LINE_LOOP", "LINE_STRIP", "TRIANGLES", "TRIANGLE_STRIP", "TRIANGLE_FAN"];
			Exception.throw_conditional(string_ext("unsupported topology type [{0}], expected [{1}]!", [mode_labels[primitive_header[$ "mode"] ?? 4], mode_labels[4]]));
			return undefined;
		}

		var accessor_index = primitive_header.indices;
		if (is_undefined(accessor_index)){ // We only support index definition through accessors
			Exception.throw_conditional("unsupported primitive definition, indices accessor required!");
			return undefined;
		}
		
		// Grab the accessor so we can fetch a list of vertex indices
		var primitive_accessor = get_structure(accessor_index, "accessors");
		if (is_undefined(primitive_accessor)){
			Exception.throw_conditional(string_ext("invalid accessor index [{0}]!", [accessor_index]));
			return undefined;
		}
		if ((primitive_accessor[$ "type"] ?? "UNKNOWN") != "SCALAR"){
			Exception.throw_conditional(string_ext("unsupported index type [{0}], expected type [SCALAR].", [primitive_accessor[$ "type"] ?? "UNKNOWN"]));
			return undefined;
		}
		
		var vertex_index_array = read_accessor(accessor_index); // Array if integers pointing to vertex data indices
		if (is_undefined(vertex_index_array)){ // If anything goes wrong, throw a generic error
			Exception.throw_conditional(string_ext("failed to read accessor [{0}]!", [accessor_index]));
			return undefined;
		}

		#region BUILD ATTRIBUTE LOOKUP
		// Now we bulid array groups of attributes that match the vertex format for quick look-up
		// when building the mesh
		var vertex_index_count = array_length(vertex_index_array);
		var missing_data = [];	// Record which data is missing so we can spit a warning
		var primitive_map = {};
		var component_type_map = {};
		for (var i = array_length(format.vformat_array) - 1; i >= 0; --i){
			var array;
			var format_label = VertexFormat.get_vertex_data_gltf_label(format.vformat_array[i]);
			var accessor_index = primitive_header.attributes[$ format_label];
			
			if (is_undefined(accessor_index)){ // Mesh doesn't contain data we are requesting; fill w/ defaults
				array = array_create(vertex_index_count, VertexFormat.get_vertex_data_default(format.vformat_array[i]));
				array_push(missing_data, format_label);
			}
			else{
				array = read_accessor(accessor_index);
				component_type_map[$ format_label] = get_buffer_ctype_from_gltf_ctype(get_structure(accessor_index, "accessors").componentType);
			}
			
			primitive_map[$ format_label] = array;
		}
		#endregion
		
		if (array_length(missing_data) > 0)
			print_traced("WARNING", "primitive definition missing requested data ", string_replace_all(json_stringify(missing_data, false), "\"", "") + "!");
		
		// Build the primitive itself:
		var is_custom_transform = not is_undefined(transform);
		var primitive = new Primitive(format);
		primitive.define_begin();
		for (var i = array_length(format.vformat_array) - 1; i >= 0; --i){
			var format_label = VertexFormat.get_vertex_data_gltf_label(format.vformat_array[i]);
			var array = primitive_map[$ format_label];
			var component_type = (component_type_map[$ format_label] ?? buffer_f32);
			for (var j = 0; j < vertex_index_count; ++j){
				var data = array[vertex_index_array[j]];
					// Colors can come in various datatypes; handle the integer versions
				#region COLOR DATA SPECIAL-HANDLING
				if (format.vformat_array[i] == VERTEX_DATA.color){
					var div_value = 0;
					if (component_type == buffer_u16)
						div_value = 65535;
					else if (component_type == buffer_u8)
						div_value = 255;
					
					data = (is_quat(data) ? quat_to_array(data) : vec_to_array(data));
					if (div_value > 0){
						for (var k = array_length(data) - 1; k >= 0; --k)
							data[k] /= div_value;
					}
						
					data = [make_color_rgb(data[0] * 255, data[1] * 255, data[2] * 255), array_length(data) > 3 ? data[3] : 1.0];
				}
				#endregion
				else if (format.vformat_array[i] == VERTEX_DATA.position and is_custom_transform){
					var result = matrix_transform_vertex(transform, data.x, data.y, data.z, 1.0);
					data = vec(result[0], result[1], result[2]);
				}
				else if (format.vformat_array[i] == VERTEX_DATA.normal and is_custom_transform){
					var result = matrix_transform_vertex(transform, data.x, data.y, data.z, 0.0);
					data = vec_normalize(vec(result[0], result[1], result[2]));
				}
				
				#region TANGENT DATA SPECIAL-HANDLING
/// @stub	handle tangents being vec(0,0,0) (aka., unset) and auto-calculate them, make sure to multiply by transform matrix
				#endregion
				
				primitive.define_add_data(format.vformat_array[i], data);
			}
		}
		primitive.define_end();
		return primitive;
/// @stub	Implement
	}
	
	/// @desc	Given a mesh index, attempts to generate a Mesh. See generate_primitive for more
	///			specifics in regards to data handling.
	function generate_mesh(mesh_index, format, apply_transforms=true){
		var count = get_primitive_count(mesh_index);
		if (count <= 0)
			return undefined;
			
		var transform = undefined;
		// Calculate transform matrix for this mesh (if one exists and apply transforms is enabled)
		if (apply_transforms){
			var node_array = (json_header[$ "nodes"] ?? []);
			for (var i = array_length(node_array) - 1; i >= 0; --i){
				var node = node_array[i];
				if ((node[$ "mesh"] ?? -1) != mesh_index)
					continue;
				
				transform = get_node_transform(i);
				break;
			}
		}
		
		var primitive_array = array_create(count, undefined);
		var is_invalid = false;
		var i;
		for (i = 0; i < count; ++i){
			var primitive = generate_primitive(mesh_index, i, format, transform);
			if (is_undefined(primitive)){
				is_invalid = true;
				break;
			}
			
			primitive_array[i] = primitive;
		}
		
		if (is_invalid){
			for (var j = 0; j < i; ++j){
				primitive_array[j].free();
				delete primitive_array[j];
			}
			Exception.throw_conditional(string_ext("failed to build mesh, invalid primitive [{0}].", [i]));
			return undefined;
		}

		// Add each primitive to the mesh and attach the material index
		var mesh = new Mesh();
		for (var i = 0; i < count; ++i)
			mesh.add_primitive(primitive_array[i], json_header.meshes[mesh_index].primitives[i][$ "material"] ?? -1);
		
		return mesh;
	}
	
	/// @desc	This will generate a Model that contains all the Mesh and Primitives
	///			defined in the file, along with their respective materials. Each
	///			element MUST be cleaned up manually!
	/// @param	{VertexFormat}	vformat		VertexFormat to generate with, will attempt to fill missing data
	/// @param	{bool}			apply=true	Whether or not node transforms should be applied to the primitives
	function generate_model(format, apply_transforms=true){
/// @stub	Remove the 'format' argument, it is just for testing
		var count = get_mesh_count();
		if (count <= 0)
			return undefined;
		
		var mesh_array = array_create(count, undefined);
		var is_invalid = false;
		var i;
		for (i = 0; i < count; ++i){
/// @stub	Determine proper format automatically if unspecified
			var mesh = generate_mesh(i, format, apply_transforms);
			if (is_undefined(mesh)){
				is_invalid = true;
				break;
			}
			
			mesh_array[i] = mesh;
		}
		
		if (is_invalid){
			for (var j = 0; j < i; ++j){
				mesh_array[j].free();
				delete mesh_array[j];
			}
			Exception.throw_conditional(string_ext("failed to build model, invalid mesh [{0}].", [i]));
			return undefined;
		}
		
		var model = new Model();
		for (var i = 0; i < count; ++i)
			model.add_mesh(mesh_array[i]);
		
		return model;
	}
	
	/// @desc	Given a node index, returns the final transform of it, post-multiplied
	///			against its parent all the way up to the root.
	function get_node_transform(node_index){
		var node_array = (json_header[$ "nodes"] ?? []);
		if (node_index < 0 or node_index >= array_length(node_array))
			return matrix_build_identity();
		
		var node = node_array[node_index];
		var transform = node[$ "matrix"];
			// Might have manual transforms:
		if (is_undefined(transform)){
			var translation = (node[$ "translation"] ?? [0, 0, 0]);
			var rotation = (node[$ "rotation"] ?? [0, 0, 0, 1]);
			var scale = (node[$ "scale"] ?? [1, 1, 1]);

			var T = matrix_build_translation(translation[0], translation[1], translation[2]);
			var R = matrix_build_quat(rotation[0], rotation[1], rotation[2], rotation[3]);
			var S = matrix_build_scale(scale[0], scale[1], scale[2]);

			transform = matrix_multiply_post(S, R, T);
		}
		
		for (var i = array_length(node_array) - 1; i >= 0; --i){
			var parent_node = node_array[i];
			var child_array = (parent_node[$ "children"] ?? []);
			if (array_contains(child_array, node_index))
				return matrix_multiply(transform, get_node_transform(i));
		}
		
		return transform;
	}
	#endregion
	
	#region INIT
	// Auto-load in the model:
	if (not load(name, directory)){ // Will auto-throw if the file doesn't exist
		if (not string_ends_with(directory, "/") and not string_ends_with(directory, "\\") and directory != "")
				directory += "/";
				
		throw new Exception(string_ext("failed to load file [{0}]!", [directory + name]));
	}
	#endregion
}