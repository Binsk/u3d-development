uniform sampler2D u_sFinalOpaque;
uniform sampler2D u_sFinalTranslucent;
uniform sampler2D u_sDepthOpaque;
uniform sampler2D u_sDepthTranslucent;
uniform int u_iRenderStages;

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
	vec4 vColorOpaque = texture2D(u_sFinalOpaque, v_vTexcoord);
	vec4 vColorTranslucent = texture2D(u_sFinalTranslucent, v_vTexcoord);
	float fDepthOpaque = texture2D(u_sDepthOpaque, v_vTexcoord).r;
	float fDepthTranslucent = texture2D(u_sDepthTranslucent, v_vTexcoord).r;
	
	vec4 vColor;
	if (u_iRenderStages == 1)
		vColor = vColorOpaque;
	else if (u_iRenderStages == 2)
		vColor = vColorTranslucent;
	else {
		if (fDepthOpaque < fDepthTranslucent)
			vColor = vColorOpaque;
		else
			vColor = (vColorTranslucent * vColorTranslucent.a) + (vColorOpaque * (1.0 - vColorTranslucent.a));
	}
	
	vColor.rgb /= vColor.rgb + vec3(1.0);
	vColor.rgb = pow(vColor.rgb, vec3(1.0 / 2.2));
	if (vColor.a > 0.0)
		vColor.a = 1.0;
	
    gl_FragColor = vColor;
}
