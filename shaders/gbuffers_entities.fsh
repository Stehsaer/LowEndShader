#version 120

#include "/lib/frameBuffer.glsl"

// varying
varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
varying vec4 lmcoord;
varying float isHurt;
varying float isExplode;

// uniform(s)
uniform sampler2D texture;

uniform vec4 entityColor;

// defines
#define HURT_COLOR vec3(1.0, 0.5, 0.5);

void main(){
  vec4 blockColor = texture2D(texture, texcoord.st) * vec4(tintColor, 1.0);
  blockColor.rgb = mix(blockColor.rgb, entityColor.rgb, entityColor.a);

	if(isHurt != 0) blockColor.rgb *= HURT_COLOR; // if hurt turn red
	if(isExplode !=0) blockColor.rgb = vec3(1.0);

  GCOLOROUT = blockColor;
  GDEPTHOUT = vec4(lmcoord.st, 0.0, 0.0);
  GNORMALOUT = vec4(normal * 0.5 + 0.5, 1.0f);
}
