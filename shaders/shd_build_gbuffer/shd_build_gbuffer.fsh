uniform sampler2D u_sAlbedo;
uniform vec4 u_vAlbedo;

varying vec2 v_vTexcoord;
varying vec4 v_vColor;

void main()
{
    gl_FragData[0] = v_vColor * u_vAlbedo * texture2D(u_sAlbedo, v_vTexcoord);
}
