#version 120

// varying
varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;
varying float isHurt;
varying float isExplode;

// uniform(s)
uniform sampler2D noisetex;

uniform int entityHurt;
uniform int entityFlash;

void main(){
  gl_Position = ftransform();

  texcoord = gl_MultiTexCoord0;
  lmcoord = gl_MultiTexCoord1;

  tintColor = gl_Color.rgb;

  normal = normalize(gl_NormalMatrix * gl_Normal);

	isHurt = float(entityHurt);
	isExplode = float(entityFlash);
}
