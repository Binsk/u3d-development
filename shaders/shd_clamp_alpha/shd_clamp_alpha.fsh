
varying vec2 v_vTexcoord;

void main()
{
	vec4 vColor = texture2D(gm_BaseTexture, v_vTexcoord);
	vColor.a = clamp(vColor.a, 0, 1);
	gl_FragColor = vColor;
}
