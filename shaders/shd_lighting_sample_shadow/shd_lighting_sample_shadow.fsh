uniform sampler2D u_sDepth;     // Regular depth
uniform sampler2D u_sShadow;    // Light's perspective depth

uniform float u_fShadowBias;
uniform mat4 u_mShadow; // World-to-projection space in the shadow map
uniform mat4 u_mInvProj;
uniform mat4 u_mInvView;

varying vec2 v_vTexcoord;

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

// Returns the amount that is in shadow (0 or 1)
float calculate_shadow(){
    vec3 vPosition = depth_to_world(texture2D(u_sDepth, v_vTexcoord).r , v_vTexcoord);
    // Convert it into the light's projection space:
    vec3 vLPosition = (u_mShadow * vec4(vPosition.xyz, 1.0)).xyz * 0.5 + 0.5; // Note, no need to div by w due to ortho projection
    
    // Sample against light's depth buffer and return if there is a shadow
    if (texture2D(u_sShadow, vLPosition.xy).r < vLPosition.z - u_fShadowBias)
        return 1.0;
    
    return 0.0;
}

void main()
{
    gl_FragColor.r = calculate_shadow();
}
