var sprite_id = async_load[? "id"];

if (is_undefined(sprite_id))	// Something went wrong, don't bother
	return;

if (is_undefined(image_track[$ sprite_id]))	// Perhaps cued by another system, ignore
	return;

/// @stub	Add cleaner way of handling this so it doesn't crash the game
if (async_load[? "status"] < 0)
	throw new Exception($"failed to load sprite [{async_load[? "filename"]}] with error [{async_load[? "status"]}]!");

// Assume all is good, call the function:
var callable = image_track[$ sprite_id];
struct_remove(image_track, sprite_id);

callable.call();
