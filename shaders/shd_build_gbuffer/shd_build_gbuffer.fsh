uniform sampler2D u_sAlbedo;
uniform sampler2D u_sNormal;
uniform sampler2D u_sPBR;
uniform ivec3 u_iSamplerToggles;

uniform vec4 u_vAlbedo;
uniform vec3 u_vPBR;

uniform float u_fZScalar; // (zFar - zNear)

varying vec2 v_vTexcoordAlbedo;
varying vec2 v_vTexcoordNormal;
varying vec2 v_vTexcoordPBR;
varying vec4 v_vColor;
varying vec3 v_vNormal;
varying vec4 v_vPosition;

vec3 to_rgb(vec3 vColor){
	bvec3 bCutoff = lessThan(vColor, vec3(0.04045));
	vec3 vHigher = pow(abs((vColor + vec3(0.055)) / vec3(1.055)), vec3(2.4));
	vec3 vLower = vColor / vec3(12.92);
	return mix(vHigher, vLower, vec3(bCutoff));
}

vec4 to_rgb(vec4 vColor){
	return vec4(to_rgb(vColor.rgb), vColor.a);
}

void main()
{
    if (u_iSamplerToggles[0] > 0) // Albedo
        gl_FragData[0] = v_vColor * u_vAlbedo * to_rgb(texture2D(u_sAlbedo, v_vTexcoordAlbedo));
    else
        gl_FragData[0] = v_vColor * u_vAlbedo;
    
    if (u_iSamplerToggles[1] > 0) // Normals
/// @stub   Need to convert to view space + combine w/ other normal
        gl_FragData[1] = vec4(texture2D(u_sNormal, v_vTexcoordNormal).rgb, 1.0);
    else
        gl_FragData[1] = vec4(v_vNormal * 0.5 + 0.5, 1.0);
    
    if (u_iSamplerToggles[2] > 0) // PBR
        gl_FragData[2] = vec4(texture2D(u_sPBR, v_vTexcoordPBR).rgb * u_vPBR, 1.0);
    else
        gl_FragData[2] = vec4(u_vPBR, 1.0);
       
	/// @note	Can't seem to get the regular method to write out correctly? This is working for now.
	gl_FragData[3].r = gl_FragCoord.z / gl_FragCoord.w / u_fZScalar; // Convert from [-1..1] to [0..1]
}
