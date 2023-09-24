#version 300 es
precision highp float;

uniform vec3 u_Target;
uniform vec3 u_Eye;
uniform float u_Time;
uniform float u_Fov;
uniform vec2 u_WindowSize;

in vec2 fs_Pos; // uv
out vec4 out_Col;

#define zoom   0.800
#define tile   0.850
#define speed  0.010

#define iterations 17
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

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
vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

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
void main() {
  float time = u_Time * speed;
  if(time > 10000.0f)
    time -= 10000.0f;
  vec2 uv = gl_FragCoord.xy / u_WindowSize;
  vec2 uvNorm = 2.f * uv - 1.f;

  float aspectRatio = u_WindowSize.x / u_WindowSize.y;
  vec3 forward = normalize(u_Target - u_Eye);
  vec3 right = normalize(cross(forward, vec3(0, 1, 0)));
  vec3 up = cross(forward, right);
  float halfFov = u_Fov / 2.0f;
  vec3 rayDirection = normalize(forward + uvNorm.x * tan(halfFov) * aspectRatio * right + uvNorm.y * tan(halfFov) * up);

  vec3 vColor = vec3(0.1f, 0.2f, 0.4f) * uv.y;
  float starValue = starField(rayDirection * 200.f, 0.8f);

  out_Col = vec4(abs(starValue),abs(starValue),abs(starValue),1.f);
}