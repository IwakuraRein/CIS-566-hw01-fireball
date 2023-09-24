#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform float u_Time;
uniform float u_MovingSpeed;
uniform float u_CellNum;
uniform float u_PatternSize;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec2 fs_UV;
in vec3 fs_Pos;
in vec3 fs_Displacement;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 hash3(vec3 p) {
    float time = u_Time * u_MovingSpeed;
    if(time > 10000.0f)
        time -= 10000.0f;
    p = vec3(dot(p, vec3(127.1f, 311.7f, 74.7f)), dot(p, vec3(269.5f, 183.3f, 246.1f)), dot(p, vec3(113.5f, 271.9f, 124.6f)));
    p = -1.0f + 2.0f * fract(sin(p) * 43758.5453123f);
    return sin(p * 6.283f + time);
}
float interpolate(float value1, float value2, float value3, float value4, float value5, float value6, float value7, float value8, vec3 t) {
    return mix(mix(mix(value1, value2, t.x), mix(value3, value4, t.x), t.y), mix(mix(value5, value6, t.x), mix(value7, value8, t.x), t.y), t.z);
}
vec3 fade(vec3 t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}
vec3 fade2(vec3 p, vec3 corner) {
    vec3 t = abs(p - corner);
    return vec3(1.0f) - (6.0f * t * t * t * t * t - 15.0f * t * t * t * t + 10.0f * t * t * t);
}
float perlin(vec3 p) {
    vec3 pi = floor(p); // min corner of the cell
    vec3 pf = fract(p); // fraction of the point within the cell
    float ret = 0.0f;
    for(float dx = 0.; dx <= 1.; ++dx) {
        for(float dy = 0.; dy <= 1.; ++dy) {
            for(float dz = 0.; dz <= 1.; ++dz) {
                vec3 corner = pi + vec3(dx, dy, dz);
                vec3 g = normalize(hash3(corner));
                vec3 d = pf - vec3(dx, dy, dz);
                vec3 f = fade2(p, corner);
                ret += dot(g, d) * f.x * f.y * f.z;
            }
        }
    }
    return ret;
}

// doesn't work
float perlin2(vec3 p) {
    vec3 pi = floor(p);
    vec3 pf = fract(p);

    vec3 f;
    float ret = 0.;

    vec3 corner = pi + vec3(.0f, .0f, .0f);
    float influence = dot(normalize(hash3(corner)), pf - vec3(.0f, .0f, .0f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;

    corner = pi + vec3(.0f, .0f, 1.f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.0f, .0f, 1.f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;

    corner = pi + vec3(.0f, 1.f, 0.f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.0f, 1.f, 0.f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;
    
    corner = pi + vec3(.0f, 1.f, 1.f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.0f, 1.f, 1.f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;
    
    corner = pi + vec3(.1f, .0f, .0f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.1f, .0f, .0f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;
    
    corner = pi + vec3(.1f, .0f, 1.f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.1f, .0f, 1.f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;
    
    corner = pi + vec3(.1f, 1.f, 0.f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.1f, 1.f, 0.f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;
    
    corner = pi + vec3(.1f, 1.f, 1.f);
    influence = dot(normalize(hash3(corner)), pf - vec3(.1f, 1.f, 1.f));
    f = fade2(p, corner);
    ret += influence * f.x * f.y * f.z;

    return ret;
    //return f000 + f001 + f010 + f011 + f100 + f101 + f110 + f111;
    // return interpolate(f000, f001, f010, f011, f100, f101, f110, f111, fade(pf));
}

float FBM(vec3 p) {
    p *= 4.f;
    float a = 1.f, r = 0.f, s = 0.f;

    for(int i = 0; i < 5; i++) {
        r += a * perlin(p);
        s += a;
        p *= 2.f;
        a *= .5f;
    }

    return r / s;
}

void main() {
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        //float ambientTerm = 0.2;

        //float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color

    float brightness = FBM(fs_Pos * u_PatternSize);
    float lightIntensity = 0.6 * brightness + 0.4;
    lightIntensity += min( max( 1.0 - 0.3 * ( 1.0 - brightness ), 0.0 ), 1.0 );

    float disp = dot(fs_Displacement, fs_Nor.xyz);
    vec3 dispColor = vec3(0.8, 0.2, 0.1) * lightIntensity;
    vec3 fireColor = diffuseColor.rgb * lightIntensity;


    out_Col = vec4(mix(fireColor, dispColor, max(0.f, disp*10.f)), diffuseColor.a);
}
