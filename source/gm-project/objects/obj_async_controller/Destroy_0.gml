/// @note	This instance should never be manually destroyed; cleanup is fine.
///			If it is destroyed, there might be missed data syncs which can result
///			in broken textures or never-ending load cycles.
Exception.throw_conditional("async controller destroyed, this should never happen!");