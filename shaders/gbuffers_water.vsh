#version 120

attribute vec4 mc_Entity;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;
varying float ide;
varying vec4 colorOverlay;

void main(){
  float blockId = mc_Entity.x;
  gl_Position = ftransform();
  if(blockId == 8 || blockId == 9) {
    ide = 0.8;
    colorOverlay = vec4(67, 120, 224, 60);
  } else {
    ide = 0.0;
    colorOverlay = vec4(1.0);
  }

  color = gl_Color;
  texcoord = gl_MultiTexCoord0;
  lmcoord = gl_MultiTexCoord1;
  normal = normalize(gl_NormalMatrix * gl_Normal);
}
