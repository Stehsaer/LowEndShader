#version 120

varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;

varying vec4 lmcoord;
varying float entity;
varying float glow;

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
  vec4 position = gl_Vertex;
  float blockId = mc_Entity.x;
  entity = blockId;

  #ifdef WAVING_GRASS  // waving plants. NOTE: waving water and leaves have problems where shadows can't display properly. not fixed.
  if((blockId == 31.0 || blockId == 37.0 || blockId == 38.0 || mc_Entity.x == 141.0 || mc_Entity.x == 142.0 || mc_Entity.x == 59.0) && gl_MultiTexCoord0.t < mc_midTexCoord.t)
  { // single block plant. eg. grass, crops
    float blockId = mc_Entity.x;
    vec3 noise = texture2D(noisetex, position.xz / 256.0).rgb;
    float maxStrength = 1.0 + rainStrength * 0.5;
    float time = frameTimeCounter * 3.0;
    float reset = cos(noise.z * 10.0 + time * 0.1);
    reset = max( reset * reset, max(rainStrength, 0.1));
    position.x += sin(noise.x * 10.0 + time) * 0.07 * reset * maxStrength;
    position.z += sin(noise.y * 10.0 + time) * 0.07 * reset * maxStrength;
  }
  else if(mc_Entity.x == 175.0 || mc_Entity.x == 83.0 )
  { // multiple blocks need to be synced. eg. tall grass
    vec3 noise = texture2D(noisetex, (position.xz + 0.5) / 16.0).rgb;
    float maxStrength = 1.0 + rainStrength * 0.5;
    float time = frameTimeCounter * 3.0;
    float reset = cos(noise.z * 10.0 + time * 0.1);
    reset = max( reset * reset, max(rainStrength, 0.1));
    position.x += sin(noise.x * 10.0 + time) * 0.07 * reset * maxStrength;
    position.z += sin(noise.y * 10.0 + time) * 0.07 * reset * maxStrength;
  }
  #endif

  tintColor = gl_Color.rgb;

  if(blockId == 119.0 || blockId == 50.0 || blockId == 51.0 || blockId == 124.0 || blockId == 169.0 || blockId == 198.0 || blockId == 10.0 || blockId == 11.0 || blockId == 89.0 || blockId == 91.0 || blockId == 90.0 || blockId == 138.0 || blockId == 213.0 || blockId == 720.0) glow = 1.0; else glow = 0.0;
  //if(blockId == 8.0 || blockId == 9.0) tintColor == vec3(0.2,0.2,0.5); water code, not used when gbuffers_water is used
  position = gl_ModelViewMatrix  * position;

  gl_Position = gl_ProjectionMatrix * position;

  texcoord = gl_MultiTexCoord0;
  lmcoord = gl_MultiTexCoord1;

  normal = normalize(gl_NormalMatrix * gl_Normal);
}
