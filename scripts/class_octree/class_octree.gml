/// ABOUT
/// This is a strict Octree that subdivides spaces into equally-sized octants.
/// This partitioning system excells at partitioning 3D points that do not
/// have any volume. Octrees CAN be used to partition physical bodies, and loose
/// octrees are generally better at that task, however either case generally has
/// a very large number of scans to find the desired space(s) and a BVH is
/// generally more preferable.

function Octree() : Partition() constructor {
	
}