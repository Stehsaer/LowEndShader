#version 120

// varying
varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;

// uniform(s)
uniform sampler2D noisetex;

void main(){
  gl_Position = ftransform();

  texcoord = gl_MultiTexCoord0;
  lmcoord = gl_MultiTexCoord1;

  tintColor = gl_Color.rgb;

  normal = normalize(gl_NormalMatrix * gl_Normal);
}
