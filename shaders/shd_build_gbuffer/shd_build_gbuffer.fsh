#ifdef _YY_GLSLES_
uniform sampler2D u_sInput;
uniform int u_iCompatability;	// Which compatability pass we're on
#else
uniform sampler2D u_sAlbedo;
uniform sampler2D u_sNormal;
uniform sampler2D u_sPBR;
uniform sampler2D u_sEmissive;
#endif

uniform ivec4 u_iSamplerToggles;
uniform vec4 u_vAlbedo;
uniform vec3 u_vPBR;
uniform vec3 u_vEmissive;
uniform float u_fAlphaCutoff;
uniform int u_iTranslucent;

varying vec2 v_vTexcoord;
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

vec4 calculate_albedo(){
	vec4 vColor;
    if (u_iSamplerToggles[0] > 0)
    	#ifdef _YY_GLSLES_
        vColor = v_vColor * u_vAlbedo * to_rgb(texture2D(u_sInput, v_vTexcoord));
        #else
        vColor = v_vColor * u_vAlbedo * to_rgb(texture2D(u_sAlbedo, v_vTexcoord));
        #endif
    else
        vColor = v_vColor * u_vAlbedo;
       
    if (u_iTranslucent <= 0) {
    	if (vColor.a < u_fAlphaCutoff)
    		discard;
    	else
    		vColor.a = 1.0;
    }
    
    return vColor;
}

vec3 calculate_normal(){
	vec3 vNormal = vec3(0, 0, 1);
    if (u_iSamplerToggles[1] > 0){ // Textured normals
    	#ifdef _YY_GLSLES_
    	vNormal = texture2D(u_sInput, v_vTexcoord).rgb * 2.0 - 1.0;
    	#else
    	vNormal = texture2D(u_sNormal, v_vTexcoord).rgb * 2.0 - 1.0;
    	#endif
    	vNormal = normalize(v_mRotation * vNormal); // Multiply by TBN, unfortunately has to be in the fragment shader
    }
    else
    	vNormal = v_mRotation[2];
    
    if (!gl_FrontFacing)
		vNormal = -vNormal;
	
	return vNormal;
}

vec4 calculate_pbr(){
	if (u_iSamplerToggles[2] > 0)
	/// @stub	Allow storing specular in R channel; however some exports are filling it with garbage so we need a special toggle somewhere
		#ifdef _YY_GLSLES_
		return vec4(vec3(1.0, texture2D(u_sInput, v_vTexcoord).gb) * u_vPBR, 1.0);
		#else
		return vec4(vec3(1.0, texture2D(u_sPBR, v_vTexcoord).gb) * u_vPBR, 1.0);
		#endif
	else 
		return vec4(u_vPBR, 1.0);
}

vec4 calculate_emission(){
	if (u_iSamplerToggles[3] > 0){
		#ifdef _YY_GLSLES_
		vec4 vEmission = texture2D(u_sInput, v_vTexcoord);
		#else
		vec4 vEmission = texture2D(u_sEmissive, v_vTexcoord);
		#endif
		return vec4(to_rgb(vEmission.rgb) * u_vEmissive, vEmission.a);
	}
	else
		return vec4(0, 0, 0, 0);
}

#ifndef _YY_GLSLES_
// Full MRT render:
void main()
{
    gl_FragData[0] = calculate_albedo();
    gl_FragData[1] = vec4(calculate_normal() * 0.5 + 0.5, 1.0);
    gl_FragData[2] = calculate_pbr();
    gl_FragData[3] = calculate_emission();
}
#else
// Simplified GLSL ES render
void main(){
	if (u_iCompatability == 0)
		gl_FragColor = calculate_albedo();
	else if (u_iCompatability == 1)
		gl_FragColor = vec4(calculate_normal() * 0.5 + 0.5, 1.0);
	else if (u_iCompatability == 2)
		gl_FragColor = calculate_pbr();
	else 
		gl_FragColor = calculate_emission();
}
#endif