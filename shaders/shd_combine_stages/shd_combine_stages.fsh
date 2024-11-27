uniform sampler2D u_sFinalOpaque;
uniform sampler2D u_sFinalTranslucent;
uniform sampler2D u_sDepthOpaque;
uniform sampler2D u_sDepthTranslucent;
uniform int u_iRenderStages;

varying vec2 v_vTexcoord;

void main()
{
	vec4 vColorOpaque = texture2D(u_sFinalOpaque, v_vTexcoord);
	vec4 vColorTranslucent = texture2D(u_sFinalTranslucent, v_vTexcoord);
	float fDepthOpaque = texture2D(u_sDepthOpaque, v_vTexcoord).r;
	float fDepthTranslucent = texture2D(u_sDepthTranslucent, v_vTexcoord).r;
	
	vec4 vColor;
	if (u_iRenderStages == 1)	// Only opaque stage
		vColor = vColorOpaque;
	else if (u_iRenderStages == 2)	// Only translucent stage
		vColor = vColorTranslucent;
	else { // Both stages, do a regular color blend
		if (fDepthOpaque < fDepthTranslucent) // If opaque is in front, no need to blend as it covers
			vColor = vColorOpaque;
		else
			vColor = (vColorTranslucent * vColorTranslucent.a) + (vColorOpaque * (1.0 - vColorTranslucent.a));
		
		vColor.a = max(vColorTranslucent.a, vColorOpaque.a);
	}
	
	gl_FragColor = vColor;
}
