#version 120

#include "/lib/frameBuffer.glsl"

varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;

const int noiseTextureResolution = 256;

uniform sampler2D texture;

void main(){
  vec4 blockColor = texture2D(texture, texcoord.st); // basically the same
  blockColor.rgb *= tintColor;

  GCOLOROUT = blockColor;
  GDEPTHOUT = vec4(lmcoord.st, 0.0, 1.0);
  GNORMALOUT = vec4(normal * 0.5 + 0.5, 0.0f);
}
