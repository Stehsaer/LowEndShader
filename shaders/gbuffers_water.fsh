#version 120

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;
varying float ide;
varying vec4 colorOverlay;

uniform sampler2D texture;

void main(){
  vec4 blockCol = colorOverlay / 256.0;

  gl_FragData[0] = blockCol;
  gl_FragData[1] = vec4(lmcoord.st, ide, ide);
  gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0f);
  gl_FragData[4] = vec4(ide, 0.0, 0.0, 0.0);
}
