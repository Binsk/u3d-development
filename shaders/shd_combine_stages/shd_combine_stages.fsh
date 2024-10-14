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
	
    gl_FragColor = vColor;
}
