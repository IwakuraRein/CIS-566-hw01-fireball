#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.
uniform float u_Time;
uniform float u_MorhpingSpeed;
uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.
in vec2 vs_UV;

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec2 fs_UV;
out vec3 fs_Pos;
out vec3 fs_Displacement;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * .1031f);
  p3 += dot(p3, p3.yzx + 33.33f);
  return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3) {
  p3 = fract(p3 * .1031f);
  p3 += dot(p3, p3.zyx + 31.32f);
  return fract((p3.x + p3.y) * p3.z);
}
vec3 hash33(vec3 p3) {
  p3 = fract(p3 * vec3(.1031f, .1030f, .0973f));
  p3 += dot(p3, p3.yxz + 33.33f);
  return fract((p3.xxy + p3.yxx) * p3.zyx);

}

vec3 displacement1(vec3 vertPos, vec3 nor, float amp, float time) {
  return nor * cos(nor.x + time) * cos(nor.y + time) * cos(nor.z + time) * sin(time) * amp;
}
vec3 displacement2(vec3 vertPos, vec3 nor, float amp, float time) {
  float frequency = 0.4f;
  float y = sin(vertPos.x * frequency);
  y += sin(vertPos.x * frequency * 2.1f + time) * 4.5f;
  y += sin(vertPos.y * frequency * 1.72f + time * 1.121f) * 4.0f;
  y += sin(vertPos.z * frequency * 2.221f + time * 0.437f) * 5.0f;
  y *= amp * 0.06f;
  return nor * y;
}

float fractalBrownian(vec3 vertPos, float amp, int layers, float time) {
  float frequency = 0.4f;
  float result = 0.f;
  for(int i = 0; i < layers; ++i) {
    result += (sin(vertPos.x * frequency + time) + sin(vertPos.y * frequency + time) + sin(vertPos.z * frequency + time)) * amp;
    frequency *= 1.5f;
    amp *= 0.5f;
  }
  return result;
}
float NoisyStarField(vec3 samplePos, float threshold) {
  float StarVal = hash13(samplePos.xyz);
  if(StarVal >= threshold)
    StarVal = pow((StarVal - threshold) / (1.0f - threshold), 6.0f);
  else
    StarVal = 0.0f;
  return StarVal;
}
float starField(in vec3 samplePos, float threshhold)
{
    vec3 fractXYZ = fract(samplePos);
    vec3 floorSample = floor(samplePos);

    float v1 = NoisyStarField(floorSample, threshhold);
    float v2 = NoisyStarField(floorSample + vec3(0.0, 0.0, 1.0), threshhold);
    float v3 = NoisyStarField(floorSample + vec3(0.0, 1.0, 0.0), threshhold);
    float v4 = NoisyStarField(floorSample + vec3(0.0, 1.0, 1.0), threshhold);
    float v5 = NoisyStarField(floorSample + vec3(1.0, 0.0, 0.0), threshhold);
    float v6 = NoisyStarField(floorSample + vec3(1.0, 0.0, 1.0), threshhold);
    float v7 = NoisyStarField(floorSample + vec3(1.0, 1.0, 0.0), threshhold);
    float v8 = NoisyStarField(floorSample + vec3(1.0, 1.0, 1.0), threshhold);

    float StarVal = v1 * (1.0 - fractXYZ.x) * (1.0 - fractXYZ.y) * (1.0 - fractXYZ.z) +
                    v2 * (1.0 - fractXYZ.x) * (1.0 - fractXYZ.y) * fractXYZ.z +
                    v3 * (1.0 - fractXYZ.x) * fractXYZ.y * (1.0 - fractXYZ.z) +
                    v4 * (1.0 - fractXYZ.x) * fractXYZ.y * fractXYZ.z +
                    v5 * fractXYZ.x * (1.0 - fractXYZ.y) * (1.0 - fractXYZ.z) +
                    v6 * fractXYZ.x * (1.0 - fractXYZ.y) * fractXYZ.z +
                    v7 * fractXYZ.x * fractXYZ.y * (1.0 - fractXYZ.z) +
                    v8 * fractXYZ.x * fractXYZ.y * fractXYZ.z;
    return StarVal;
}
float FBM(vec3 p, float time) {
  p += time;
  float a = 1.f, r = 0.f, s = 0.f;


  //layer1, triangle wave on y
  r += abs(p.y - floor(p.y / a) * a - 0.5 * a) * 2.f;
  s += a;
  p *= 2.f;
  a *= .7f;

  //layer2, smooth wave on z
  r += p.z - floor(p.z);
  s += a;
  p *= 2.f;
  a *= .7f;

  //layer3, sin wave on x
  r += a * sin(p.x);
  s += a;
  p *= 2.f;
  a *= .7f;

  //layer4, blue noise

  r += a * starField(p*10.f, 0.2f);
  s += a;
  p *= 2.f;
  a *= .7f;

  return r / s;
}

void main() {
  fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
  fs_UV = vs_UV;
  mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

  vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

  float time = u_Time;
  if(time > 10000.0f)
    time -= 10000.0f;

  // fs_Displacement = displacement1(modelposition.xyz, fs_Nor.xyz, 0.15f, time * u_MorhpingSpeed);
  // fs_Displacement += displacement2(modelposition.xyz * 50.f, fs_Nor.xyz, 0.02f, time * u_MorhpingSpeed * 8.f);

  fs_Displacement += fs_Nor.xyz * FBM(modelposition.xyz, time * u_MorhpingSpeed) * 0.3f;
  modelposition.xyz += fs_Displacement;

  fs_Pos = modelposition.xyz;

  fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

  gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
