#version 120

// FRAGDATA:
// 0 = color texture
// 1 = depth texture vec4( lightmap.torchlight, lightmap.skylight, identity of block, mix ratio of block)
// 2 = normal texture

#include "/lib/frameBuffer.glsl"

#define SHADOWS
  const int shadowMapResolution       = 2048; // shadowMapResolution [512 1024 2048 4096 8192]
  const float sunPathRotation         = -30.0; // sunPathAngles [-0.0 -10.0 -20.0 -30.0 -40.0 -50.0 -60.0]
  const float shadowDistance          = 90.0; //[32.0 50.0 64.0 72.0 90.0 128.0 256.0 384.0 512.0 1024.0]
  const float shadowBias 		    = 1.0 - 25.6 / shadowDistance;
  const float shadowDistanceRenderMul = 1f;

  const int R8 = 0;
  const int colortex4Format = R8;

#define SHADOW_MAP_BIAS 0.6
#define MULTIPLE_SHADOW

#define CLOUDS

const int RGBA16 = 1;
const int GCOLORFORMAT = RGBA16;

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying vec3 voidColor;
varying vec3 cloudColor;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float near;
uniform float far;

uniform sampler2D gdepthtex;
uniform sampler2D shadow;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
uniform sampler2D colortex4;

uniform int worldTime;
uniform int isEyeInWater;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
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

//shadow code
vec4 getCameraSpacePosition(vec2 coord){
  float depth = getDepth(coord);
  vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
  vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;
  return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePosition(in vec2 coord){
  vec4 positionCameraSpace = getCameraSpacePosition(coord);
  vec4 positionWorldSpace = gbufferModelViewInverse * positionCameraSpace;
  //positionWorldSpace.xyz = cameraPosition; (save GPU Cycle)
  return positionWorldSpace;
}

vec3 getShadowSpacePosition(in vec2 coord){
  vec4 positionWorldSpace = getWorldSpacePosition(coord);
  //positionWorldSpace.xyz -= cameraPosition; (save GPU Cycle)
  vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
  positionShadowSpace = shadowProjection * positionShadowSpace;
  float distb = sqrt(positionShadowSpace.x * positionShadowSpace.x + positionShadowSpace.y * positionShadowSpace.y);
  float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
  positionShadowSpace.xy /= distortFactor;
  positionShadowSpace /= positionShadowSpace.w;
  return positionShadowSpace.xyz = positionShadowSpace.xyz * 0.5 + 0.5;
}

float getCasterVisibility(in vec2 coord){  // change: merged all function can save GPU Cycles?
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

  for(float x = -0.5; x <= 0.5; x += 0.5){ // 3 * 3 = 9 samples, better quality
    for(float y = -0.5; y <=0.5; y += 0.5){
      float shadowMapSample = texture2D(shadow, shadowCoord.st + vec2(x, y) / shadowMapResolution).r;
      returnValue += step(shadowCoord.z - shadowMapSample, 0.0002);
    }
  }

  return returnValue / 9;
  #else

  float shadowMapSample = texture2D(shadow, shadowCoord.st).r; // single sample, better performance
  return step(shadowCoord.z - shadowMapSample, 0.0002);

  #endif
}
//shadow code end

//calculate lighting code
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
  float directLightStrength = dot(lightVector, frag.normal);
  directLightStrength = max(0.0, directLightStrength);
  vec3 directLight = vec3(directLightStrength) * lightmap.skyLightStrength / 256.0 * (1.0 - rainStrength);
  #ifdef SHADOWS
  directLight *= lightColor * getCasterVisibility(texcoord.st);
  #endif

  vec3 torchColor = vec3(1.0, 0.867, 0.6);
  vec3 torchLight = torchColor * lightmap.torchLightStrength / 256.0;
  vec3 lit_color = frag.albedo * (torchLight * 0.7 + directLight + skyColor);
  if(isEyeInWater == 1) lit_color *= vec3(0.5, 0.5, 1.0);

  return mix(lit_color, frag.albedo, frag.emission);
}

//lighting code end

//cloud render code
#define CLOUD_HEIGHT 512.0 // cloud height

float noise(in vec3 x){
    vec3 p = ceil(x);
    vec3 f = fract(x);
    f = smoothstep(0.0, 1.0, f);

    vec2 uv = (p.xy+vec2(90.0, 17.0)*p.z) + f.xy;
    float v1 = texture2D( noisetex, (uv)/256.0, -100.0 ).x;
    float v2 = texture2D( noisetex, (uv + vec2(90.0, 17.0))/256.0, -100.0 ).x;
    return mix(v1, v2, f.z);
}

float getCloudNoise(in vec3 worldPos) { // cloud noise
    vec3 coord = worldPos;
    coord.x += frameTimeCounter * 10.0;
    coord *= 0.002;
    float n  = noise(coord) * 0.5;   coord *= 3.0;
          n += noise(coord) * 0.25;  coord *= 3.0;
          n += noise(coord) * 0.125; coord *= 3.0;
          n += noise(coord) * 0.0625;
    return max(n - 0.5, 0.0) * (1.0 / (1.0 - 0.5));
}

float getCloudAlpha(in vec3 color, in vec3 rayDir){  //sep code for alpha calculating(unused)
  float alpha = 0;
  float deltaHeight = CLOUD_HEIGHT - cameraPosition.y;
  vec3 worldPos = vec3(
    cameraPosition.x + rayDir.x / rayDir.y * deltaHeight,
    CLOUD_HEIGHT,
    cameraPosition.z + rayDir.z / rayDir.y * deltaHeight
    );
  alpha = getCloudNoise(worldPos);
  if(rayDir.y <= 0.2){
    alpha *= max(0.0, (rayDir.y - 0.1) * 10);
  }
  return alpha;
}

vec3 getCloud(in vec3 color, in vec3 rayDir){ // main cloud rendering
  float alpha = 0;
  float deltaHeight = CLOUD_HEIGHT - cameraPosition.y;
  vec3 worldPos = vec3(
    cameraPosition.x + rayDir.x / rayDir.y * deltaHeight,
    CLOUD_HEIGHT,
    cameraPosition.z + rayDir.z / rayDir.y * deltaHeight
    );
  alpha = getCloudNoise(worldPos);
  if(rayDir.y <= 0.2){
    alpha *= max(0.0, (rayDir.y - 0.1) * 10);
  }
  return mix(color, cloudColor, min(alpha * 8.0, 1.0));
}

// cloud rendering end

float linearizeDepth(in float depth) { //linearize depth from screen space depth
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 waterReflection(in vec3 color, in vec3 normal, in vec3 viewPos){ //developing
  vec3 afterRef = reflect(normalize(viewPos), normal);
  if(dot(afterRef, lightVector) > 0.99) return vec3(1.0); else return color;
}

void main(){ // main void
  float depth = texture2D(depthtex1, texcoord.st).x;
  Fragment fragd = getFragment(texcoord.st);
  Lightmap lightmap = getLightMap(texcoord.st);
  vec3 finalColor = calculateLighting(fragd, lightmap); // calc shadow

  float terrain = getTerrain(texcoord.st);

  vec4 viewPosition = gbufferProjectionInverse * vec4(texcoord.s * 2.0 - 1.0, texcoord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0f);
  viewPosition /= viewPosition.w;
  vec3 rayDir = normalize(gbufferModelViewInverse * viewPosition).xyz; //init draw cloud

  if(terrain == 1.0) finalColor = voidColor / 256.0; // fix white-color void
  if(terrain == 1.0 && rayDir.y > 0.0){ // deal with void problems
    if(worldTime >= 13800 && worldTime < 22200){ // above horizon: stars
      finalColor = vec3(1.0);
    }
    else { // under horizon: void
      finalColor = voidColor / 256.0;
    }
  }

  if(terrain == 0.3) finalColor = vec3(0.0,0.0,0.0); //test code(?)

  #ifdef CLOUDS
  if(rayDir.y > 0.1 && terrain == 0.5)
  finalColor = getCloud(finalColor, rayDir); //finalColor = rayDir;
  #endif

  if(rayDir.y > 0.0 && terrain == 0.5) finalColor *= vec3(max(1.0, 1 + (1 - rayDir.y) * 0.5));

  if(abs(fragd.emission - 0.8) <= 0.01){ // under development
    //finalColor = waterReflection(finalColor, fragd.normal, viewPosition.xyz);
  }

  //finalColor = vec3(linearizeDepth(depth));
  if(terrain == 0.0) finalColor = mix(finalColor, voidColor / 256.0, clamp(linearizeDepth(depth) * 10 - 6, 0.0, 1.0)); // fog

  float brightness = dot(finalColor.rgb, vec3(0.2126, 0.7152, 0.0722)); // calc BLOOM
  vec3 highlight = finalColor.rgb * max(brightness - 0.25, 0.0);

/* DRAWBUFFERS:01 */
  gl_FragData[0] = vec4(finalColor,1.0);
  gl_FragData[1] = vec4(highlight, 1.0);
}
