#version 120

varying vec3 tintColor;

#include "/lib/frameBuffer.glsl"

void main(){
  GCOLOROUT = vec4(tintColor / 256.0, 1.0);
  GDEPTHOUT = vec4(0.0, 0.0, 0.0, 1.0);
}
