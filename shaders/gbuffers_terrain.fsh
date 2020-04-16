#version 120

#include "/lib/frameBuffer.glsl"

varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;

varying float glow;

varying float entity;

const int noiseTextureResolution = 256;

uniform sampler2D texture;

void main(){
  vec4 blockColor = texture2D(texture, texcoord.st);

  vec3 tintColor2 = tintColor * (1.0 + glow * 0.5);

  blockColor.rgb *= tintColor2;

  GCOLOROUT = blockColor;
  GDEPTHOUT = vec4(lmcoord.st, 0.0, glow);
  GNORMALOUT = vec4(normal * 0.5 + 0.5, 1.0f);
}
