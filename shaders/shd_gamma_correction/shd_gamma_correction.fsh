uniform sampler2D u_sInput;
varying vec2 v_vTexcoord;

void main()
{
    vec4 vColor = texture2D(u_sInput, v_vTexcoord);
    
    // Gamma correction:
    vColor.rgb /= vColor.rgb + vec3(1.0);
    vColor.rgb = pow(vColor.rgb, vec3(1.0 / 2.2));
    gl_FragColor = vColor;
}
