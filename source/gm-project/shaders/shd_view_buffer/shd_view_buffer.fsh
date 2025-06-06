precision highp float;

uniform sampler2D u_sDepth;			// Current pass's depth

uniform mat4 u_mInvProj;
uniform mat4 u_mInvView;
uniform vec3 u_vCamPosition;

varying vec2 v_vTexcoord;

/// @desc	Convert the cached depth value into a position in world space.
vec3 depth_to_world(float fDepth, vec2 vUV){
	#ifdef _YY_HLSL11_
    float fZ = fDepth;
    vec4 vClipPos = vec4(vUV.x * 2.0 - 1.0, (1.0 - vUV.y) * 2.0 - 1.0, fZ, 1.0);
    #else
    float fZ = fDepth * 2.0 - 1.0;
    vec4 vClipPos = vec4(vUV.xy * 2.0 - 1.0, fZ, 1.0);
    #endif
    
    vec4 vViewPos = u_mInvProj * vClipPos;
    vViewPos /= vViewPos.w;
    return (u_mInvView * vViewPos).xyz;
}

void main()
{
    float fDepth = texture2D(u_sDepth, v_vTexcoord).r;
    
    vec3 vView = normalize(depth_to_world(fDepth, v_vTexcoord) - u_vCamPosition);
    gl_FragColor = vec4(vView * 0.5 + 0.5, 1.0);
}
