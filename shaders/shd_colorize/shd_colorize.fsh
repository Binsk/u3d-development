uniform sampler2D u_sInput;
uniform vec3 u_vColor;

varying vec2 v_vTexcoord;

void main()
{
    vec4 vColor = texture2D(u_sInput, v_vTexcoord);
    vColor.rgb *= u_vColor;
    gl_FragColor = vColor;
}
