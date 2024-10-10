uniform sampler2D u_sAlbedo;
uniform sampler2D u_sNormal;
uniform sampler2D u_sPBR;
uniform sampler2D u_sEmissive;
uniform ivec4 u_iSamplerToggles;

uniform vec4 u_vAlbedo;
uniform vec3 u_vPBR;
uniform vec3 u_vEmissive;

uniform float u_fZScalar; // (zFar - zNear)

varying vec2 v_vTexcoordAlbedo;
varying vec2 v_vTexcoordNormal;
varying vec2 v_vTexcoordPBR;
varying vec2 v_vTexcoordEmissive;
varying vec4 v_vColor;
varying vec3 v_vNormal;
varying vec4 v_vPosition;
varying mat3 v_mRotation;

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
    
    vec3 vNormal = vec3(0, 0, 1);
    if (u_iSamplerToggles[1] > 0) // Textured normals
    	vNormal = texture2D(u_sNormal, v_vTexcoordNormal).rgb * 2.0 - 1.0;
    
    if (!gl_FrontFacing)
		vNormal = -vNormal;
	
/// @stub	Think of some way to calculate normals in the vertex shader! Normally would do things
///			in tangent space, but can't do so with a a deferred render.	
	vNormal = normalize(v_mRotation * vNormal);
		
    gl_FragData[1] = vec4(vNormal.xyz * 0.5 + 0.5, 1.0);
    
    if (u_iSamplerToggles[2] > 0){ // PBR
/// @stub	Allow storing specular in R channel; however some exports are filling it with garbage so we need a special toggle somewhere
        gl_FragData[2] = vec4(vec3(1.0, texture2D(u_sPBR, v_vTexcoordPBR).gb) * u_vPBR, 1.0);
    }
    else
        gl_FragData[2] = vec4(u_vPBR, 1.0);

	// Emissive texture:
	if (u_iSamplerToggles[3] > 0)
		gl_FragData[3] = vec4(to_rgb(texture2D(u_sEmissive, v_vTexcoordEmissive).rgb) * u_vEmissive, 1.0);
	else
		gl_FragData[3] = vec4(0, 0, 0, 1);
}
