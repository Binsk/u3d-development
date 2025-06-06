# FIXME
-	Cube-mapping seams, especially noticeable w/ the fake mips
-	Framerate drops drastically in cycles. It comes and goes and depends on
	what I was doing, but I was getting drops from 200 to 40 where then it would
	inch up to drop again. Seems it may be animation related. Increasing the
	update frequency to max helps show it best.
-	Controller body detachments likely only execute the parent detach
	script and not the child.
-	Duck normal texture not loading correctly; have tried re-exporting via gimp
	and even shrunk and it still doesn't work right.
-	Fix "framebuffer" error in browser when loading new textures in (if rendering is off
	while loading the issue goes away).
-	Fix browser dithered rendering not mixing right w/ opaque items (?)

# TODO
-	[widows] address multple 'attribute' inputs for shaders
-	System currently renders camera mirrored: to fix some issues;
	this is bad if we want in-game camera rendering so find a way to fix the
	projection matrix.
-	Camera pipeline toggles (e.g., skip shadows, skip emission, lighting pass, 
	etc) so that in-game cameras can have modified renders apart from the actual
	resources being rendered. Allows, e.g., dynamic cube-mapping that can ignore
	certain things.
-	Lots of file load stuff is async, so consider switching the GLTFBuilder to
	that.
-	Add model/mesh/primitve "optimizing" that attempts to combine primitives
	and meshes under a model into a new single primitive for optimized rendering.
-	Add some kind of PrimitiveBuilder where you can define a single primitev along
	with a number of copies and matrices and it generates a 'multi-primitive' version
	to render lots of copies as one.
-	Add support for attaching bone indices to meshes (not bodies) as some glTF models require this.
-	Implement dual-quaternion skinning, both for better animation transforms and
	less bandwidth to the GPU.
	https://rodolphe-vaillant.fr/entry/29/dual-quaternions-skinning-tutorial-and-c-codes
	This is mostly a skinning method, so just doing a quat+offset pair could also work
	for bandwidth reasons, but it would still be linear.
	NOTE: Storage buffers would be better for bone data, but GameMaker doesn't support
	them.
-	Add translucent shadow mapping
-	Implement shadow sampling optimization (make it sample outer edges first, if
	they are all dark assume the inside ones are and exit early)
-	Add proper animation forming w/ tracks that don't define all bones; may 
	require default skeleton bones to be multiplied?
-	Add blend type for animation layers (replace, like what I'm currently doing, or merge)
-	Implement morph targets for glTF loading: https://github.com/KhronosGroup/glTF-Tutorials/blob/main/gltfTutorial/gltfTutorial_017_SimpleMorphTarget.md
	It is effectively vertex morphing animation.
-	Look into Intel's improved (and faster) SSAO: https://github.com/GameTechDev/XeGTAO
-	Add support for Linear / sRGB space toggling in textures! Needed for things like cube-mapping
	and sky-boxes since they are blended at different stages of the pipeline.
-	Add support for 'hooks' w/ custom properties when loading glTF; this will allow
	changing generation w/ game-specific properties defined in blender.
-	Add dithered translucency to opaque pass (apart form current mixed rendering)
-	Add dynamic number of 'translucent' render layers; user defined
-	Add optimized culling of buffers in compatability mode (e.g., if no emissive materials
	drop that pass entirely).
-	Add BVH 2D representation for checking branch depths
-	BVH updating instances is WAY TOO SLOW!
-	Optional automatic animation culling when something is out-of-view of cameras or
	even an animation update lerp speed
-	Add a 'queue' mode to the signaler system to allow the async controller to execute
	all at once; along w/ a way to override arguments. This, mostly to get around
	repeated set_position() etc. calls.
-	Add static option in U3DObject to auto-generate unique hash upon spawn. Should be easy,
	but requires the special dynamic hashes to work through the system.