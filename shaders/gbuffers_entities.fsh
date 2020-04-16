#version 120

#include "/lib/frameBuffer.glsl"

varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;

const int noiseTextureResolution = 64;

uniform sampler2D texture;
uniform vec4 entityColor;

void main(){
  vec4 blockColor = texture2D(texture, texcoord.st) * vec4(tintColor, 1.0);
  blockColor.rgb = mix(blockColor.rgb, entityColor.rgb, entityColor.a);

  GCOLOROUT = blockColor;
  GDEPTHOUT = vec4(lmcoord.st, 0.0, 0.0);
  GNORMALOUT = vec4(normal * 0.5 + 0.5, 1.0f);
}
