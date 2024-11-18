uniform sampler2D u_sTexture;
uniform int u_iTonemap; // Tonemap style (see enum CAMERA_TONEMAP)
uniform int u_iGamma;	// Whether or not to apply gamma correction
uniform float u_fExposure;
uniform float u_fWhite;

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
	
	vColor.rgb *= u_fExposure;
	
	if (u_iTonemap == 1){// Reinhard
		// vColor.rgb /= vColor.rgb + vec3(1.0);
		vColor.rgb = vColor.rgb * (1.0 + vColor.rgb / (u_fWhite * u_fWhite)) / (1.0 + vColor.rgb);
	}
	else if (u_iTonemap == 2){ // ACES
		float fA = 2.51;
		float fB = 0.03;
		float fC = 2.43;
		float fD = 0.59;
		float fE = 0.14;
		vColor.rgb = clamp((vColor.rgb * (fA * vColor.rgb + fB)) / (vColor.rgb * (vColor.rgb * fC + fD) + fE), 0.0, 1.0);
		vColor.rgb /= u_fWhite;
	}
	
	// Gamma correction:
	if (u_iGamma > 0)
		vColor.rgb = pow(vColor.rgb, vec3(1.0 / 2.2));
	
	// if (vColor.a > 0.0) // Fix issues w/ translucent combination but still allow stenciling out
	// 	vColor.a = 1.0;
		
	gl_FragColor = vColor;
}
