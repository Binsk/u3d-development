uniform vec2 u_vDirection;
uniform vec2 u_vTexelSize;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 vColor = vec4(0.0);
    vec2 vOff1 = vec2(1.411764705882353) * u_vDirection;
    vec2 vOff2 = vec2(3.2941176470588234) * u_vDirection;
    vec2 vOff3 = vec2(5.176470588235294) * u_vDirection;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord) * 0.1964825501511404;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord + (vOff1 * u_vTexelSize)) * 0.2969069646728344;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord - (vOff1 * u_vTexelSize)) * 0.2969069646728344;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord + (vOff2 * u_vTexelSize)) * 0.09447039785044732;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord - (vOff2 * u_vTexelSize)) * 0.09447039785044732;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord + (vOff3 * u_vTexelSize)) * 0.010381362401148057;
    vColor += texture2D(gm_BaseTexture, v_vTexcoord - (vOff3 * u_vTexelSize)) * 0.010381362401148057;
    
    gl_FragColor = v_vColour * vColor;
}
