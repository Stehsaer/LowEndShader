#version 120

// varyings
varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;

// attributes
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

// uniforms
//		mat4
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
//		int
uniform int worldTime;
//		float
uniform float frameTimeCounter;
uniform float rainStrength;
//		sampler2D
uniform sampler2D noisetex;

// define(s)
#define WAVING_GRASS

void main(){
  gl_Position = ftransform();

  texcoord = gl_MultiTexCoord0;
  lmcoord = gl_MultiTexCoord1;

  tintColor = gl_Color.rgb;

  normal = normalize(gl_NormalMatrix * gl_Normal);
}
