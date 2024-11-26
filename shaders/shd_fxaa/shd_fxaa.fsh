uniform sampler2D u_sInput;
uniform vec2 u_vTexelSize;

varying vec2 v_vTexcoord;

/// @note   Taken from an old project that took this from somewhere else. Can't
///         be bothered to update all the variable names. -.-'

void main( void ) {
    float FXAA_SPAN_MAX = 8.0;
    float FXAA_REDUCE_MUL = 1.0 / 8.0;
    float FXAA_REDUCE_MIN = 1.0 / 128.0;

    vec4 rgbNW=texture2D(u_sInput,v_vTexcoord+(vec2(-1.0,-1.0) * u_vTexelSize));
    vec4 rgbNE=texture2D(u_sInput,v_vTexcoord+(vec2(1.0,-1.0) * u_vTexelSize));
    vec4 rgbSW=texture2D(u_sInput,v_vTexcoord+(vec2(-1.0,1.0) * u_vTexelSize));
    vec4 rgbSE=texture2D(u_sInput,v_vTexcoord+(vec2(1.0,1.0) * u_vTexelSize));
    vec4 rgbM=texture2D(u_sInput,v_vTexcoord);

    vec4 luma=vec4(0.299, 0.587, 0.114, 0.0);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 vDir;
    vDir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    vDir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
        FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0/(min(abs(vDir.x), abs(vDir.y)) + dirReduce);

    vDir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
          max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
          vDir * rcpDirMin)) * u_vTexelSize;

    vec4 rgbA = (1.0/2.0) * (
        texture2D(u_sInput, v_vTexcoord.xy + vDir * (1.0/3.0 - 0.5)) +
        texture2D(u_sInput, v_vTexcoord.xy + vDir * (2.0/3.0 - 0.5)));
    vec4 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
        texture2D(u_sInput, v_vTexcoord.xy + vDir * (0.0/3.0 - 0.5)) +
        texture2D(u_sInput, v_vTexcoord.xy + vDir * (3.0/3.0 - 0.5)));
    float lumaB = dot(rgbB.rgb, luma.rgb);

    if((lumaB < lumaMin) || (lumaB > lumaMax)){
        gl_FragColor.rgb=rgbA.rgb;
    }else{
        gl_FragColor.rgb=rgbB.rgb;
    }
    
    gl_FragColor.a = rgbM.a;
    
    // Added to remove yellow outline if no render background / environment 
    // is specified.
    if (rgbNW.a < 1.0 || rgbNE.a < 1.0 || rgbSW.a < 1.0 || rgbSE.a < 1.0  || 
        rgbM.a < 1.0 || rgbA.a < 1.0 || rgbB.a < 1.0)
        gl_FragColor = rgbM;
}