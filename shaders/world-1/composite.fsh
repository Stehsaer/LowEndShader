#version 120

#include "/lib/frameBuffer.glsl"

#define SHADOWS
  const int shadowMapResolution       = 2048; // shadowMapResolution [512 1024 2048 4096 8192]
  const float sunPathRotation         = -30.0; // sunPathAngles [-0.0 -10.0 -20.0 -30.0 -40.0 -50.0 -60.0]
  const float shadowDistance          = 90.0; //[32.0 50.0 64.0 72.0 90.0 128.0 256.0 384.0 512.0 1024.0]
  const float shadowBias 		    = 1.0 - 25.6 / shadowDistance;
  const float shadowDistanceRenderMul = 1f;

#define SHADOW_MAP_BIAS 0.6
#define MULTIPLE_SHADOW

const int RGBA16 = 1;
const int GCOLORFORMAT = RGBA16;

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying vec3 voidColor;

uniform sampler2D gdepthtex;
uniform sampler2D shadow;

uniform vec3 cameraPosition;
uniform int isEyeInWater;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

struct Fragment{
  vec3 albedo;
  vec3 normal;

  float emission;
};

struct Lightmap{
  float torchLightStrength;
  float skyLightStrength;
};

float getDepth(in vec2 coord){
  return texture2D(gdepthtex, coord).r;
}

vec4 getCameraSpacePosition(vec2 coord){
  float depth = getDepth(coord);
  vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
  vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;
  return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePosition(in vec2 coord){
  vec4 positionCameraSpace = getCameraSpacePosition(coord);
  vec4 positionWorldSpace = gbufferModelViewInverse * positionCameraSpace;
  //positionWorldSpace.xyz = cameraPosition;
  return positionWorldSpace;
}

vec3 getShadowSpacePosition(in vec2 coord){
  vec4 positionWorldSpace = getWorldSpacePosition(coord);
  //positionWorldSpace.xyz -= cameraPosition;
  vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
  positionShadowSpace = shadowProjection * positionShadowSpace;
  float distb = sqrt(positionShadowSpace.x * positionShadowSpace.x + positionShadowSpace.y * positionShadowSpace.y);
  float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
  positionShadowSpace.xy /= distortFactor;
  positionShadowSpace /= positionShadowSpace.w;
  return positionShadowSpace.xyz = positionShadowSpace.xyz * 0.5 + 0.5;
}

float getCasterVisibility(in vec2 coord){
  float depth = getDepth(coord);
  vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
  vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;
  positionCameraSpace = positionCameraSpace / positionCameraSpace.w; //getCameraSpacePosition(coord);

  vec4 positionWorldSpace = gbufferModelViewInverse * positionCameraSpace;
  //positionWorldSpace.xyz = cameraPosition;

  //positionWorldSpace.xyz -= cameraPosition;
  vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
  positionShadowSpace = shadowProjection * positionShadowSpace;
  float distb = sqrt(positionShadowSpace.x * positionShadowSpace.x + positionShadowSpace.y * positionShadowSpace.y);
  float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
  positionShadowSpace.xy /= distortFactor;
  positionShadowSpace /= positionShadowSpace.w;
  vec3 shadowCoord =  positionShadowSpace.xyz = positionShadowSpace.xyz * 0.5 + 0.5;

  //vec3 shadowCoord = getShadowSpacePosition(coord);
  #ifdef MULTIPLE_SHADOW
  float returnValue = 0;
  for(float x = -0.5; x <= 0.5; x += 0.5){
    for(float y = -0.5; y <=0.5; y += 0.5){
      float shadowMapSample = texture2D(shadow, shadowCoord.st + vec2(x, y) / shadowMapResolution).r;
      returnValue += step(shadowCoord.z - shadowMapSample, 0.0002);
    }
  }
  return returnValue / 9;
  #else
  float shadowMapSample = texture2D(shadow, shadowCoord.st).r;
  return step(shadowCoord.z - shadowMapSample, 0.0002);
  #endif
}

Fragment getFragment(in vec2 coord){
  Fragment newfrag;

  newfrag.albedo   = getAlbedo(coord);
  newfrag.normal   = getNormal(coord);
  newfrag.emission = getEmission(coord);

  return newfrag;
}

Lightmap getLightMap(in vec2 coord){
  Lightmap lightmap;
  lightmap.torchLightStrength = getTorchLight(coord);
  lightmap.skyLightStrength = getSkyLight(coord);
  return lightmap;
}

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap){
  vec3 torchColor = vec3(1.0, 0.867, 0.6);
  vec3 torchLight = torchColor * lightmap.torchLightStrength / 240.0;
  vec3 lit_color = frag.albedo * (torchLight * 1.3 + vec3(0.3));
  if(isEyeInWater == 1) lit_color *= vec3(0.5, 0.5, 1.0);
  return mix(lit_color, frag.albedo, frag.emission);
}


void main(){
  Fragment fragd = getFragment(texcoord.st);
  Lightmap lightmap = getLightMap(texcoord.st);
  vec3 finalColor = calculateLighting(fragd, lightmap);

  if(getTerrain(texcoord.st) == 1.0) finalColor = vec3(0.0);
  //finalColor = vec3(getTerrain(texcoord.st));

  float brightness = dot(finalColor.rgb, vec3(0.2126, 0.7152, 0.0722));
  vec3 highlight = finalColor.rgb * max(brightness - 0.25, 0.0);
/* DRAWBUFFERS:01 */
  gl_FragData[0] = vec4(finalColor,1.0);
  gl_FragData[1] = vec4(highlight, 1.0);
}
