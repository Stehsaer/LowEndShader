#version 120

#include "/lib/frameBuffer.glsl"

// uniforms
uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

//varyings
varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying vec3 voidColor;
varying vec3 cloudColor;

void main(){
  gl_Position = ftransform();

  texcoord = gl_MultiTexCoord0;

  if (worldTime < 12000 && worldTime >= 0) {
		lightColor = vec3(1.0);
    lightVector = normalize(sunPosition);
    skyColor = vec3(0.3);
	}
  if (worldTime < 22200 && worldTime >= 13800) {
		lightColor = vec3(0.1);
    lightVector = normalize(moonPosition);
    skyColor = vec3(0.1);
	}
  if (worldTime < 24000 && worldTime >= 22200) {
		lightColor = vec3(0.1 + 0.9 * (worldTime - 22200f) / 1800f);
    lightVector = normalize(sunPosition);
    skyColor = vec3(0.1 + 0.2 * (worldTime - 22200f) / 1800f);
	}
  if (worldTime >= 12000 && worldTime < 13800) {
    lightColor = vec3(1.0 - 0.9 * (worldTime - 12000f) / 1800f);
    lightVector = normalize(sunPosition);
    skyColor = vec3(0.3 - 0.2 * (worldTime - 12000f) / 1800f);
  }

	// customized variable pass-downs
  voidColor = getSkyColor(worldTime); // pass down void Colors to fsh
  cloudColor = getCloudColor(worldTime) / 256.0; // pass down cloud color to fsh
}
