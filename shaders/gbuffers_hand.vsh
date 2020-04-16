#version 120

varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;

varying vec4 lmcoord;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;

uniform float rainStrength;

uniform sampler2D noisetex;

#define WAVING_GRASS

void main(){
  gl_Position = ftransform();

  texcoord = gl_MultiTexCoord0;
  lmcoord = gl_MultiTexCoord1;

  tintColor = gl_Color.rgb;

  normal = normalize(gl_NormalMatrix * gl_Normal);
}
