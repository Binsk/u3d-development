/// @about
/// A generic partitioning class that defines the common interaction functions
/// that are common among all space partitioning algorithms. This provides an easy
/// way to swap out partitioning systems without needing to adjust any calling
/// functions.

/// @note	Partitioning systems should be able to have either methods or 
///			struct type definitions that define how data is handled. This way
///			a user can wrap a generic piece of data and have it handled properly.

function Partition() : U3DObject() constructor {
	
}