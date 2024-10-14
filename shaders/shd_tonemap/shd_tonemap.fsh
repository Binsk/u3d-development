uniform sampler2D u_sTexture;
uniform int u_iTonemap; // Tonemap style (see enum CAMERA_TONEMAP)

varying vec2 v_vTexcoord;

vec3 to_srgb(vec3 vColor){
	bvec3 bCutoff = lessThan(vColor, vec3(0.0031308));
	vec3 vHigher = vec3(1.055) * pow(abs(vColor), vec3(1.0 / 2.4) - vec3(0.055));
	vec3 vLower = vColor * vec3(12.92);
	return mix(vHigher, vLower, vec3(bCutoff));
}

vec4 to_srgb(vec4 vColor){
	return vec4(to_srgb(vColor.rgb), vColor.a);
}

void main()
{
    vec4 vColor = texture2D(u_sTexture, v_vTexcoord);
    
    if (u_iTonemap == 1){ // Simple
        // Gamma correction:
        vColor.rgb /= vColor.rgb + vec3(1.0);
	    vColor.rgb = pow(vColor.rgb, vec3(1.0 / 2.2));
    }
    
    if (vColor.a > 0.0) // Fix issues w/ translucent combination but still allow stenciling out
		vColor.a = 1.0;
		
    gl_FragColor = vColor;
}
