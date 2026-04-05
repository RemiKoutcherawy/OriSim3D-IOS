#include <metal_stdlib>
using namespace metal;
struct Uniforms {
  float4x4 mvp;
  float4 color;
  uint useTexture;
};
struct VertOut {
  float4 pos [[position]];
  float2 uv;
};
vertex VertOut vertexTextured(uint vid [[vertex_id]],
  const device packed_float3 *positions [[buffer(0)]],
  const device float2 *uvs      [[buffer(1)]],
  constant Uniforms   &u        [[buffer(2)]]) {
  VertOut o;
  o.pos = u.mvp * float4(float3(positions[vid]), 1.0);
  o.uv  = uvs[vid];
  return o;
}
fragment float4 fragmentTextured(VertOut in [[stage_in]],
  constant Uniforms &u [[buffer(2)]],
  texture2d<float> tex [[texture(0)]],
  sampler s            [[sampler(0)]]) {
  if (u.useTexture)
    return tex.sample(s, in.uv);
  else
    return u.color;
}
vertex VertOut vertexColored(uint vid [[vertex_id]],
  const device packed_float3 *positions [[buffer(0)]],
  constant Uniforms   &u        [[buffer(2)]]) {
  VertOut o;
  o.pos = u.mvp * float4(float3(positions[vid]), 1.0);
  o.uv  = float2(0);
  return o;
}
fragment float4 fragmentColored(VertOut in [[stage_in]],
  constant Uniforms &u [[buffer(2)]]) {
  return u.color;
}
