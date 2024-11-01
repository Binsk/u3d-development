/// @about
/// The GLTFBuilder is an extension of the GLTFLoader that provides functions for
/// constructing in-game meshes, materials, and the like out of the buffer data
/// contained within. Unless you are doing something very specific or custom, 
/// you should load in GLTF / GLB files with this rather than the GLTFLoader().
///
/// All structures generated by the builder will be automatically freed once no
/// references of them exist anymore.
///
/// @note	The GLTFBuilder does NOT support the full glTF spec and all of its
///			nuances. It was designed to handle general-case usage of Blender exports.
function GLTFBuilder(name="", directory="") : GLTFLoader() constructor {
	#region PROPERTIES
	self.name = name;
	#endregion
	
	#region METHODS
	/// @desc	Given a node index, returns the final transform of it, post-multiplied
	///			against its parents all the way up to the root.
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

			transform = matrix_multiply_post(T, R, S);
		}
		
		for (var i = array_length(node_array) - 1; i >= 0; --i){
			var parent_node = node_array[i];
			var child_array = (parent_node[$ "children"] ?? []);
			if (array_contains(child_array, node_index))
				return matrix_multiply(transform, get_node_transform(i));
		}
		
		return transform;
	}
	
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
/// @stub	Implement; currently just defaulting to "everything". Will require special
///			shader combination (ugh) or an external library for dynamic shader compilation
///			(even more ugh).
		return VertexFormat.get_format_instance([VERTEX_DATA.position, VERTEX_DATA.color, VERTEX_DATA.texture, VERTEX_DATA.normal, VERTEX_DATA.tangent, VERTEX_DATA.bone_indices, VERTEX_DATA.bone_weights]);
	}
	
	/// @desc	Returns an array of animation track names defined for this model.
	///			Animations are NOT guaranteed to have names, so if an animation is found
	///			but no name exists its name will be specified as 'undefined'
	function get_animation_track_names(){
		// Check if there is an 'animation' section
		if (is_undefined(json_header[$ "animations"]))
			return [];
			
		var animation_array = json_header[$ "animations"];
		var array = array_create(array_length(animation_array), undefined);
		for (var i = array_length(array) - 1; i >= 0; --i)
			array[i] = animation_array[i][$ "name"];
		
		return array;
	}
	
	function get_animation_track_count(){
		if (is_undefined(json_header[$ "animations"]))
			return 0;
		
		return array_length(json_header[$ "animations"]);
	}
	
	/// @desc	Returns the number of skins defined for this model; used with 
	///			animation tracks.
	function get_skin_count(){
		if (is_undefined(json_header[$ "skins"]))
			return 0;
		
		return array_length(json_header[$ "skins"]);
	}
	
	/// @desc	Generates an array of spatial materials. Note that the materials
	///			will have dynamically-generated textures attached! Textures are re-used
	///			across generations to save memory, however materials are newly generated
	///			each time.
	function generate_material_array(){
		var material_data_array = json_header[$ "materials"];
		var material_array = array_create(array_length(material_data_array), undefined);
		var sprite_data_array = json_header[$ "images"];
		var texture_array = [];
		
		// First add new sprites to the system:
		for (var i = 0; i < array_length(sprite_data_array); ++i){
			var texture_hash = md5_string_utf8($"{self.load_directory}{self.name}_sprite_texture_{i}");
			var texture = U3DObject.get_ref_data(texture_hash);
			if (not is_undefined(texture)){ // Value already loaded
				array_push(texture_array, texture);
				continue;
			}
			
			var data = sprite_data_array[i];
			var sprite;
			if (not is_undefined(data[$ "uri"])){ // External file, load normally
				if (not file_exists(load_directory + data.uri)){
					Exception.throw_conditional(string_ext("failed to find image [{0}].", [load_directory + data.uri]));
					continue;
				}
				
				sprite = sprite_add(load_directory + data.uri, 1, false, false, 0, 0);
				if (sprite < 0)
					throw new Exception(string_ext("failed to add sprite [{0}]!", [load_directory + data.uri]));
					
				texture = new Texture2D(sprite_get_texture(sprite, 0));
				texture.hash = texture_hash;	// Mark that this is a dynamic resource
				texture.signaler.add_signal("cleanup", new Callable(texture, sprite_delete), [sprite]);
				
				add_child_ref(texture);
				array_push(texture_array, texture);
				continue;
			}

			// Data buffer, must write to disk to re-load as PNG/JPG
			if (string_lower(data.mimeType) != "image/png" and string_lower(data.mimeType) != "image/jpeg"){
				Exception.throw_conditional(string_ext("unsupported mime type [{0}].", [data.mimeType]));
				continue;
			}

			var buffer = read_buffer_view(data.bufferView);
			if (is_undefined(buffer)){
				Exception.throw_conditional(string_ext("failed to read buffer view [{0}].", [data.bufferView]));
				continue;
			}

			// Save the image data to disk:
			buffer_save(buffer, "__import");
			sprite = sprite_add("__import", 1, false, false, 0, 0); // Load w/ GameMaker's function
			
			if (sprite < 0){ // If a problem, clean up and skip
				buffer_delete(buffer);
				file_delete("__import");
				
				Exception.throw_conditional("failed to add sprite from buffer!");
				continue;
			}
	
			buffer_delete(buffer);
			file_delete("__import");
			
			texture = new Texture2D(sprite_get_texture(sprite, 0));
			texture.hash = texture_hash;	// Mark that this is a dynamic resource
			texture.signaler.add_signal("cleanup", new Callable(texture, sprite_delete, [sprite]));
			
			add_child_ref(texture);
			array_push(texture_array, texture);
		}
		
		// Next generate the material data:
		for (var i = 0; i < array_length(material_data_array); ++i){
			var material_hash = md5_string_utf8($"{self.load_directory}{self.name}_material_{i}");
			var material = U3DObject.get_ref_data(material_hash);
			if (not is_undefined(material)){
				material_array[i] = material;
				continue
			}
			
			var material_data = material_data_array[i];
			var pbr_data = material_data[$ "pbrMetallicRoughness"]; // May not be set!
			// First, a quick check to see if we failed to load the sprite and fill w/ 'no texture'
			if (not is_undefined(pbr_data) and not is_undefined(pbr_data[$ "baseColorTexture"]) and is_undefined(texture_array[pbr_data[$ "baseColorTexture"]])){
				material_array[i] = U3D.RENDERING.MATERIAL.missing.duplicate();
				continue;
			}
			
			// Defaults:
			var color_base = [1, 1, 1, 1];
			var color_texture = undefined;
			var pbr_base = [1, 1, 1];
			var pbr_texture = undefined;
			var normal_texture = undefined;
			var emissive_texture = undefined;
			var emissive_base = [1, 1, 1];
			var cull_mode = (material_data[$ "doubleSided"] ?? false) ? cull_noculling : cull_counterclockwise;
			var alpha_cutoff = (material_data[$ "alphaCutoff"] ?? 0.5);
			var is_translucent = false;
			
/// @stub	Add support for pulling texture texCoord properties in case textures are shared!
///			Should be added to the Texture2D class
			if (not is_undefined(pbr_data)){
				color_base = pbr_data[$ "baseColorFactor"] ?? color_base;
				// Albedo Texture
				if (not is_undefined(pbr_data[$ "baseColorTexture"])){
					var texture_index = get_structure(pbr_data[$ "baseColorTexture"].index, "textures").source;
					color_texture = texture_array[texture_index];
				}
				// PBR Texture
				if (not is_undefined(pbr_data[$ "metallicRoughnessTexture"])){
					var texture_index = get_structure(pbr_data[$ "metallicRoughnessTexture"].index, "textures").source;
					pbr_texture = texture_array[texture_index];
				}
				// PBR Factors (note, specular is always 1):
				if (not is_undefined(pbr_data[$ "roughnessFactor"]))
					pbr_base[PBR_COLOR_INDEX.roughness] = pbr_data[$ "roughnessFactor"];
				
				if (not is_undefined(pbr_data[$ "metallicFactor"]))
					pbr_base[PBR_COLOR_INDEX.metalness] = pbr_data[$ "metallicFactor"];
			}
			
			if (not is_undefined(material_data[$ "normalTexture"])){
				var texture_index = get_structure(material_data[$ "normalTexture"].index, "textures").source;
				normal_texture = texture_array[texture_index];
			}
			
			if (not is_undefined(material_data[$ "emissiveTexture"])){
				var texture_index = get_structure(material_data[$ "emissiveTexture"].index, "textures").source;
				emissive_texture = texture_array[texture_index];
				emissive_base = (material_data[$ "emissiveFactor"] ?? [1, 1, 1]);
			}
			
			switch (material_data[$ "alphaMode"] ?? "OPAQUE"){
				case "OPAQUE":	// Effectively the same as "MASK" but doesn't allow transparency
					alpha_cutoff = 0.0;
				case "MASK":	// Alpha is either 0 or 1, this being determined by the alpha cutoff
					is_translucent = false;
					break;
				case "BLEND":	// Allows translucency
					is_translucent = true;
					break;
				default:
					Exception.throw_conditional($"invalid alphaMode [{material_data[$ "alphaMode"]}]");
			}
			
			material = new MaterialSpatial();
			
			if (not is_undefined(color_texture))
				material.set_texture("albedo", color_texture);
			if (not is_undefined(pbr_texture))
				material.set_texture("pbr", pbr_texture);
			if (not is_undefined(normal_texture))
				material.set_texture("normal", normal_texture);
			if (not is_undefined(emissive_texture))
				material.set_texture("emissive", emissive_texture);
			
			material.scalar.albedo = color_base;
			material.scalar.pbr = pbr_base;
			material.scalar.emissive = emissive_base;
			material.cull_mode = cull_mode;
			material.alpha_cutoff = alpha_cutoff;
			material.render_stage = (is_translucent ? CAMERA_RENDER_STAGE.translucent : CAMERA_RENDER_STAGE.opaque);
			material.hash = material_hash;
			add_child_ref(material);
			
			/// @note	The material will auto-dereference the texture
			material_array[i] = material;
		}
		
/// @note	Textures will be kept in memory so long as this instance exists in case of 
///			generating / removing things back-to-back.
			
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
		
		var primitive_hash = md5_string_utf8($"{self.load_directory}{self.name}_primitive_{mesh_index}{primitive_index}{format.get_hash()}{transform}");
		var primitive = U3DObject.get_ref_data(primitive_hash);
		if (not is_undefined(primitive))
			return primitive;
		
		var min_vec = get_data(["model_data", "minimum"], vec(infinity, infinity, infinity));		// Used to record generic vertex data
		var max_vec = get_data(["model_data", "maximum"], vec(-infinity, -infinity, -infinity));
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
		
		var vertex_index_array = read_accessor(accessor_index); // Array of integers pointing to vertex data indices
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
		var map_size = 0;
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
			map_size = max(map_size, array_length(array));
		}
		#endregion
		
		if (array_length(missing_data) > 0)
			print_traced("WARNING", "primitive definition missing requested data ", string_replace_all(json_stringify(missing_data, false), "\"", "") + "!");
		
		// Build the primitive itself:
		var is_custom_transform = not is_undefined(transform);
		primitive = new Primitive(format);
		primitive.hash = primitive_hash;
		primitive.define_begin(map_size);
		
		var has_tangent_data = (format.get_has_data(VERTEX_DATA.position) and format.get_has_data(VERTEX_DATA.tangent) and format.get_has_data(VERTEX_DATA.texture)); // Used when auto-calculating tangents
		var loop = array_length(format.vformat_array);
		for (var i = 0; i < loop; ++i){
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
				#region POSITION / NORMAL DATA SPECIAL-HANDLING
				else if (format.vformat_array[i] == VERTEX_DATA.position){
					if (is_custom_transform){
						var result = matrix_transform_vertex(transform, data.x, data.y, data.z, 1.0);
						data = vec(result[0], result[1], result[2]);
					}
					min_vec.x = min(min_vec.x, data.x);
					min_vec.y = min(min_vec.y, data.y);
					min_vec.z = min(min_vec.z, data.z);
					max_vec.x = max(max_vec.x, data.x);
					max_vec.y = max(max_vec.y, data.y);
					max_vec.z = max(max_vec.z, data.z);
				}
				else if (format.vformat_array[i] == VERTEX_DATA.normal and is_custom_transform){
					var result = matrix_transform_vertex(transform, data.x, data.y, data.z, 0.0);
					data = array_normalize([result[0], result[1], result[2]]);
				}
				#endregion
				#region TANGENT DATA SPECIAL-HANDLING
				else if (format.vformat_array[i] == VERTEX_DATA.tangent){
					var needs_auto_calculation = false;
					if (not is_quat(data)) // Blender exports as a vec4 for some reason? Not sure what w is for; it is always -1 or 1
						needs_auto_calculation = true;
					else
						data = vec_normalize(vec(data.x, data.y, data.z));
					
					if (vec_is_zero(data))
						needs_auto_calculation = true;
					
					// If possible, the tangent will be auto-calculated
					if (needs_auto_calculation){
						if (not has_tangent_data)
							throw new Exception("failed to auto-generate tangents, missing position and/or UV values!");
						
						// Tangents need the whole triangle to calculate, so we fetch the triangle points:
/// @todo	Lots of repeated calculations here, we could cache things so we only calculate this
///			once per face instead of once per vertex.
						var indices = [
							j - (j % 3),
							j - (j % 3) + 1,
							j - (j % 3) + 2
						];
						
						/// @note	VertexFormat guarantees that normals / UVs will be completely defined before tangents
						var vertex_array = [
							primitive.define_get_data(VERTEX_DATA.position, indices[0]),
							primitive.define_get_data(VERTEX_DATA.position, indices[1]),
							primitive.define_get_data(VERTEX_DATA.position, indices[2])
						];
						var uv_array = [
							primitive.define_get_data(VERTEX_DATA.texture, indices[0]),
							primitive.define_get_data(VERTEX_DATA.texture, indices[1]),
							primitive.define_get_data(VERTEX_DATA.texture, indices[2])
						];
						// Calculate tangent:
						var e1 = [vertex_array[1][0] - vertex_array[0][0], vertex_array[1][1] - vertex_array[0][1], vertex_array[1][2] - vertex_array[0][2]];
						var e2 = [vertex_array[2][0] - vertex_array[0][0], vertex_array[2][1] - vertex_array[0][1], vertex_array[2][2] - vertex_array[0][2]];
						var duv1 = [uv_array[1][0] - uv_array[0][0], uv_array[1][1] - uv_array[0][1]];
						var duv2 = [uv_array[2][0] - uv_array[0][0], uv_array[2][1] - uv_array[0][1]];
						var f = 1.0 / (duv1[0] * duv2[1] - duv2[0] * duv1[1]);
						var tangent = [
							f * (duv2[1] * e1[0] - duv1[1] * e2[0]),
							f * (duv2[1] * e1[1] - duv1[1] * e2[1]),
							f * (duv2[1] * e1[2] - duv1[1] * e2[2])
						];
						
						// if (vec_is_zero(tangent) or vec_is_nan(tangent))
						// 	tangent = VertexFormat.get_vertex_data_default(VERTEX_DATA.tangent);
							
						data = array_normalize(tangent);
					}
					else if (is_custom_transform){
						var result = matrix_transform_vertex(transform, data.x, data.y, data.z, 0.0);
						data = array_normalize([result[0], result[1], result[2]]);
					}
				}
				#endregion
				
				if (is_struct(data)){
					if (is_undefined(data[$ "w"]))
						data = vec_to_array(data);
					else
						data = quat_to_array(data);
				}
				
				primitive.define_set_data_raw(j, format.vformat_array[i], data, j == vertex_index_count - 1);
			}
		}
		
		primitive.define_end();
		
		add_child_ref(primitive);
		set_data(["model_data", "minimum"], min_vec);
		set_data(["model_data", "maximum"], max_vec);
		
		return primitive;
	}
	
	/// @desc	Given a mesh index, attempts to generate a Mesh. See generate_primitive for more
	///			specifics in regards to data handling.
	function generate_mesh(mesh_index, format, apply_transforms=true){
		var count = get_primitive_count(mesh_index);
		if (count <= 0)
			return undefined;
			
		var mesh_hash = md5_string_utf8($"{self.load_directory}{self.name}_mesh_{mesh_index}{format.get_hash()}{apply_transforms}");
		var mesh = U3DObject.get_ref_data(mesh_hash);
		if (not is_undefined(mesh))
			return mesh;
			
		var transform = undefined;
		// Calculate transform matrix for this mesh (if one exists and apply transforms is enabled)
		if (apply_transforms){
			var node_array = (json_header[$ "nodes"] ?? []);
			for (var i = array_length(node_array) - 1; i >= 0; --i){
				var node = node_array[i];
				if ((node[$ "mesh"] ?? -1) != mesh_index)
					continue;
				
				transform = get_node_transform(i);
				if (matrix_is_identity(transform))
					transform = undefined; // Unset as it allows faster model building
					
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
		mesh = new Mesh();
		mesh.hash = mesh_hash;

		for (var i = 0; i < count; ++i)
			mesh.add_primitive(primitive_array[i], json_header.meshes[mesh_index].primitives[i][$ "material"] ?? -1);

		return mesh;
	}
	
	/// @desc	This will generate a Model that contains all the Mesh and Primitives
	///			defined in the file, along with their respective materials. 
	/// @note	Materials and primitives generated will be auto-reused across models and cleaned up
	///			once all generated Model() instances are freed. 
	///	@note	If possible, make sure your models are exported with all transforms applied!
	///			Manually applying them upon load is slow.
	/// @param	{bool}			materials=true	Whether or not to generate materials for the model (Material indices will still be set)
	/// @param	{bool}			apply=true		Whether or not node transforms should be applied to the primitives
	/// @param	{VertexFormat}	vformat=auto	VertexFormat to generate with, will attempt to fill missing data
	function generate_model(generate_materials=true, apply_transforms=true, format=undefined){
/// @stub	Implement support for custom formats (requires dynamic shader attributes on Windows)
		if (not is_undefined(format))
			throw new Exception("custom formats not yet supported!");
		else
/// @stub	Add proper format auto-calc as appropriate once implemented
			format = get_primitive_format(-1, -1);
		
		var model_hash = md5_string_utf8($"{self.load_directory}{self.name}_model_{format.get_hash()}{generate_materials}{apply_transforms}");
		var model = U3DObject.get_ref_data(model_hash);
		if (not is_undefined(model))
			return model;
		
		set_data(["model_data", "minimum"], undefined);
		set_data(["model_data", "maximum"], undefined);
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
		
		model = new Model();
		for (var i = 0; i < count; ++i)
			model.add_mesh(mesh_array[i]);
			
		model.set_data(["aabb_min"], get_data(["model_data", "minimum"]));
		model.set_data(["aabb_max"], get_data(["model_data", "maximum"]));
		model.hash = model_hash;
		add_child_ref(model);
		
		if (not generate_materials)
			return model;
			
		// Add materials:
		var material_array = generate_material_array();
		for (var i = 0; i < array_length(material_array); ++i)
			/// @note	We mark the material as dynamic so it will auto-free w/ the model and release the textures as needed.
			model.set_material(material_array[i], i);
		
		return model;
	}
	
	/// @desc	Given an animation track name or animation track index and a skin,
	///			attempts to generate an AnimationTrack.
	/// @warning	The generated AnimationTrack MUST be manually freed when no longer
	///				needed! All sub-structures, such as AnimationTrack, will be freed
	///				along with the AnimationTrack
	function generate_animation_track(name_or_index, skin=0){
		if (is_undefined(json_header[$ "animations"]))
			return undefined;
		
		if (is_undefined(json_header[$ "skins"]))
			return undefined;
		
		if (skin < 0 or skin >= array_length(json_header[$ "skins"]))
			return undefined;
		
		#region FETCH ANIMATION HEADER
		var animation_data = undefined;
		var animation_name = "";
		if (is_string(name_or_index)){
			animation_name = name_or_index;
			var animation_array = json_header[$ "animations"];
			for (var i = array_length(animation_array) - 1; i >= 0; --i){
				if ((animation_array[i][$ "name"] ?? "") == name_or_index){
					animation_data = animation_array[i];
					break;
				}
			}
		}
		else if (is_numeric(name_or_index)){
			name_or_index = floor(name_or_index);
			var animation_array = json_header[$ "animations"];
			if (name_or_index < 0 or name_or_index >= array_length(animation_array))
				throw new Exception($"invalid track index [{name_or_index}], expected range is [0, {array_length(animation_array)})");
			
			animation_data = animation_array[name_or_index];
			animation_name = (animation_data[$ "name"] ?? string($"track_{name_or_index}"));
		}
		else
			throw new Exception("invalid type, expected [string] or [int]!");
		
		if (is_undefined(animation_data))
			throw new Exception($"invalid track, [{name_or_index}]");
		#endregion
		
		// Quick array key look-ups:
		var track_type = ["translation", "rotation", "scale"];
		var lerp_type = ["STEP", "LINEAR", "CUBICSPLINE"]; /// @note	CUBICSPLINE is UNSUPPORTED and will throw an exception!
		var skin_data = json_header.skins[skin];
		var joint_array = skin_data.joints;	// Contains node IDs that represent bone transforms
		var joint_count = array_length(joint_array);
		var channel_array = animation_data.channels;		// 1 channel = bone morphs for a single bone
		var channel_count = array_length(channel_array);
		var sampler_array = animation_data.samplers;
		var animation_track = new AnimationTrack(animation_name);
		var channelgroup_struct = {};	// Contains a channel group for each bone
		
		// Loop through each bone and collect all morphs for that bone:
		for (var i = 0; i < channel_count; ++i){
			var channel = channel_array[i];
			var sampler = sampler_array[channel.sampler];
			var bone_id = -1;
			
			// Calculate the bone id from the channel node:
			for (var j = array_length(joint_array) - 1; j >= 0; --j){
				if (joint_array[j] == channel.target.node){
					bone_id = j;
					break;
				}
			}
			
			if (bone_id < 0){
				Exception.throw_conditional($"invalid bone id [{bone_id}], no node id match [{channel.target.node}]!");
				continue;
			}
			
			// Grab / Define channel group:
			var channel_group = (channelgroup_struct[$ bone_id]);
			if (is_undefined(channel_group)){
				channel_group = new AnimationChannelGroup(bone_id);
				channelgroup_struct[$ bone_id] = channel_group;
			}
			
			var ttype = array_get_index(track_type, channel.target.path); // Correlates to BONE_PROPERTY_TYPE
			var ltype = array_get_index(lerp_type, sampler.interpolation); // Correlates to LERP_METHOD

			var animation_channel;
			if (ttype == 0)
				animation_channel = new AnimationChannelPosition(bone_id);
			else if (ttype == 1)
				animation_channel = new AnimationChannelRotation(bone_id);
			else if (ttype == 2)
				animation_channel = new AnimationChannelScale(bone_id);
			else
				throw new Exception($"invalid animation channel path, [{channel.target.path}]!");
				
			animation_channel.set_unique_hash();	// Make sure things are auto-cleaned w/ the AnimationTrack
			channel_group.set_channel(animation_channel); // Auto-sorts into position, rotation, or scale
			
			var time_range = read_accessor(sampler.input);
			var morph_range = read_accessor(sampler.output);
			var count = json_header.accessors[sampler.input].count;
			
			// Read each channel morph and add it to the channel:
			for (var j = 0; j < count; ++j)
				animation_channel.add_morph(time_range[j], morph_range[j], ltype);

			animation_channel.freeze();
		}	
		
		var group_keys = struct_get_names(channelgroup_struct);
		for (var i = array_length(group_keys) - 1; i >= 0; --i){
			var group = channelgroup_struct[$ group_keys[i]];
			group.set_unique_hash();
			animation_track.add_channel_group(group);
		}
		
		return animation_track;
	}
	
	/// @desc	Generates an animation tree containing all recognized animation
	///			tracks! If an animation track does not have a name, it will be assigned
	///			the name "track_<index>" where <index> is the index number of the track.
	///	@warning	The AnimationTree generated MUST be manually freed! All animation tracks
	///				and morphs generated will be freed automatically along with the tree.
	function generate_animation_tree(skin=0){
		var track_count = get_animation_track_count();
		if (track_count <= 0)
			return undefined;
			
		var animation_tree = new AnimationTree();
		for (var i = 0; i < track_count; ++i){
			var track = generate_animation_track(i, skin);
			if (is_undefined(track)){
				Exception.throw_conditional($"failed to generate animation track [{i}]");
				continue;
			}
			
			track.set_unique_hash();
			animation_tree.add_animation_track(track);
		}
		
		animation_tree.set_skeleton(generate_skeleton(skin));
		return animation_tree;
	}
	
	/// @desc	Generates a bone relational struct.
	///			Does NOT contain bone transform data of any kind, simply bone IDs
	///			and how they relate to each-other. Transform data is specified by
	///			animation tracks.
	function generate_skeleton(skin){
		var skin_data = get_structure(skin, "skins");
		if (is_undefined(skin_data))
			throw new Exception($"invalid skin index [{skin}]");
		
		var joint_array = skin_data.joints;
		var joint_count = array_length(joint_array);
		var matrix_inv_array = read_accessor(skin_data.inverseBindMatrices);
		
		var skeleton = {};
		// Generate bone data child relations w/o parent relations
		for (var i = 0; i < joint_count; ++i){
			var child_array = [];
			var parent_id = -1;
			
			var node = json_header.nodes[joint_array[i]];
			// Grab the child node indices:
			child_array = (node[$ "children"] ?? []);
			
			// Convert node indices into bone indices:
			for (var j = array_length(child_array) - 1; j >= 0; --j){
				var node_index = child_array[j];
				child_array[j] = array_get_index(joint_array, node_index);
			}
			
			skeleton[$ i] = {
				parent_id : -1,
				child_id_array : child_array,
				matrix_inv : matrix_inv_array[i]
			}
		}
		
		// Generate parent relations:
		for (var i = 0; i < joint_count; ++i){
			var bone = skeleton[$ i];
			var child_array = bone.child_id_array;
			for (var j = array_length(child_array) - 1; j >= 0; --j){
				var child_id = child_array[j];
				skeleton[$ child_id].parent_id = i;
			}
		}
		
		return skeleton;
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