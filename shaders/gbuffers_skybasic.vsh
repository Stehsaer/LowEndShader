#version 120

varying vec3 tintColor;

uniform int worldTime;

#include "lib/frameBuffer.glsl"

void main(){
  gl_Position = ftransform();

  tintColor = getSkyColor(worldTime);
}
