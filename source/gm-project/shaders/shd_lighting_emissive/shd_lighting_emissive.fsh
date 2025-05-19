uniform sampler2D u_sEmissive;

varying vec2 v_vTexcoord;

void main()
{
    gl_FragColor = texture2D(u_sEmissive, v_vTexcoord);
}
