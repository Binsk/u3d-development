uniform sampler2D u_sDepth;
uniform sampler2D u_sNormal;

uniform float u_fZNear;
uniform float u_fZFar;

varying vec2 v_vTexcoord;

/// Formula taken from: https://theorangeduck.com/page/pure-depth-ssao
vec3 normal_from_depth(float fDepth, vec2 vTexcoords) {
    // const float dx = 0.001;
    // const float dy = 0.001;
    // float dzdx = (texture2D(u_sDepth, vTexcoords + vec2(dx, 0)).r - texture2D(u_sDepth, vTexcoords + vec2(-dx, 0)).r) * 0.5;
    // float dzdy = (texture2D(u_sDepth, vTexcoords + vec2(0, dy)).r - texture2D(u_sDepth, vTexcoords + vec2(0, -dy)).r) * 0.5;
    // vec3 direction = vec3(-dzdx, -dzdy, 1.0);
    // return normalize(direction);
/*
dzdx=(z(x+1,y)-z(x-1,y))/2.0;
dzdy=(z(x,y+1)-z(x,y-1))/2.0;
direction=(-dxdz,-dydz,1.0)
magnitude=sqrt(direction.x**2 + direction.y**2 + direction.z**2)
normal=direction/magnitude
*/
    
  
    const vec2 vOffset1 = vec2(0.0,0.001);
    const vec2 vOffset2 = vec2(0.001,0.0);
    
    // const vec2 vOffset1 = vec2(0.0, 1.0 / 1080.0);
    // const vec2 vOffset2 = vec2(1.0 / 1920.0,0.0);
    
    float fDepth1 = texture2D(u_sDepth, vTexcoords + vOffset1).r;
    float fDepth2 = texture2D(u_sDepth, vTexcoords + vOffset2).r;
    
    vec3 p1 = vec3(vOffset1, fDepth1 - fDepth);
    vec3 p2 = vec3(vOffset2, fDepth2 - fDepth);
    
    vec3 vNormal = cross(p1, p2);
    vNormal.z = -vNormal.z;
    
    return normalize(vNormal);
}

float update_depth(float fDepth){
    return fDepth;
    // fDepth = (fDepth * 0.5 + 0.5);
    // return 2.0 * u_fZNear * u_fZFar / (u_fZFar + u_fZNear - fDepth * (u_fZFar - u_fZNear));
}

float rand(vec2 fValue){
    return abs(fract(sin(dot(fValue, vec2(12.9898, 78.233))) * 43758.5453)) * 2.0 - 1.0;
}

vec3 calculate_normal_from_xy(vec2 vXY){
	vXY = vXY * 2.0 - 1.0;
	return vec3(vXY.x, vXY.y, sqrt(-(vXY.x * vXY.x) - (vXY.y * vXY.y) + 1.0));
}

void main()
{
    const float fTotalStrength = 1.0;
    const float fBase = 0.1;
    const float fArea = 0.0075;
    const float fFalloff = 0.000001;
    const float fRadius = 0.00015;
    const int iSamples = 16;
    vec3 vSampleSphere[iSamples];
    vSampleSphere[0] = vec3( 0.5381, 0.1856,-0.4319);
    vSampleSphere[1] = vec3( 0.1379, 0.2486, 0.4430);
    vSampleSphere[2] = vec3( 0.3371, 0.5679,-0.0057);
    vSampleSphere[3] = vec3(-0.6999,-0.0451,-0.0019);
    vSampleSphere[4] = vec3( 0.0689,-0.1598,-0.8547);
    vSampleSphere[5] = vec3( 0.0560, 0.0069,-0.1843);
    vSampleSphere[6] = vec3(-0.0146, 0.1402, 0.0762);
    vSampleSphere[7] = vec3( 0.0100,-0.1924,-0.0344);
    vSampleSphere[8] = vec3(-0.3577,-0.5301,-0.4358);
    vSampleSphere[9] = vec3(-0.3169, 0.1063, 0.0158);
    vSampleSphere[10] = vec3( 0.0103,-0.5869, 0.0046);
    vSampleSphere[11] = vec3(-0.0897,-0.4940, 0.3287);
    vSampleSphere[12] = vec3( 0.7119,-0.0154,-0.0918);
    vSampleSphere[13] = vec3(-0.0533, 0.0596,-0.5411);
    vSampleSphere[14] = vec3( 0.0352,-0.0631, 0.5460);
    vSampleSphere[15] = vec3(-0.4776, 0.2847,-0.0271);
    
    vec3 vRandom = normalize(vec3(rand(v_vTexcoord.xy), rand(v_vTexcoord.yx), rand(v_vTexcoord.xy)));
    // vRandom = vec3(0, 0, 1); // No random; for testing
    float fDepth = texture2D(u_sDepth, v_vTexcoord).r;
    vec3 vPosition = vec3(v_vTexcoord.x, v_vTexcoord.y, fDepth);
    vec3 vNormal = normal_from_depth(fDepth, v_vTexcoord);
    // vec3 vNormal = normalize(calculate_normal_from_xy(texture2D(u_sNormal, v_vTexcoord.xy).rg));
    
    float fRadiusDepth = fRadius / fDepth;
    float fOcclusion = 0.0;
    float fSamples = float(iSamples);
    
    for (int i = 0; i < iSamples; ++i){
        vec3 vRay = fRadiusDepth * reflect(vSampleSphere[i], vRandom);
        vRay = normalize(vRay) * max(length(vRay), fRadiusDepth * 0.1);
        float fDot = dot(normalize(vRay), vNormal);
        vec3 vHemiRay = vPosition + sign(fDot) * vRay;
        float fOcclusionDepth = texture2D(u_sDepth, clamp(vHemiRay.xy, vec2(0, 0), vec2(1, 1))).r; 
        float fDifference = fDepth - fOcclusionDepth;
        
        fOcclusion += step(fFalloff, fDifference) * (1.0 - smoothstep(fFalloff, fArea, fDifference));
    }
    
    float fAmbientOcclusion = 1.0 - fTotalStrength * fOcclusion * (1.0 / fSamples);
    gl_FragColor.r = clamp(fAmbientOcclusion, 0.0, 1.0);
}
