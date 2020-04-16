uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform float rainStrength;

#define GCOLOROUT     gl_FragData[0]
#define GDEPTHOUT     gl_FragData[1]
#define GNORMALOUT    gl_FragData[2]

vec3 SkyCol[7] = vec3[7](
  vec3(38,104,188),
  vec3(234,160,117),
  vec3(251,143,92),
  vec3(251,82,48),
  vec3(147,63,58),
  vec3(43,23,68),
  vec3(15,15,15)
  );

vec3 cloudCol[7] = vec3[7](
  vec3(255,255,255),
  vec3(251,180,3),
  vec3(251,180,3),
  vec3(255,113,68),
  vec3(152,85,128),
  vec3(60,60,60),
  vec3(30,30,30)
  );

#define LENG 6

vec3 getAlbedo(in vec2 coord){
  return texture2D(gcolor, coord).rgb;
}

vec3 getNormal(in vec2 coord){
  return texture2D(gnormal, coord).rgb * 2.0 - 1.0;
}

float getEmission(in vec2 coord){
  return texture2D(gdepth, coord).a;
}

float getTorchLight(in vec2 coord){
  return texture2D(gdepth, coord).r;
}

float getSkyLight(in vec2 coord){
  return texture2D(gdepth, coord).g;
}

float getTerrain(in vec2 coord){
  return texture2D(gdepth, coord).b;
}

vec3 getSkyColor(int worldTime){
  vec3 tintColor = vec3(0,0,0);
  if(worldTime >= 0 && worldTime < 12000 || worldTime == 24000) tintColor = SkyCol[0];
  if(worldTime >= 13800 && worldTime < 22200) tintColor = SkyCol[6];
  if(worldTime >= 12000 && worldTime < 13800) {
    float phase = float(worldTime - 12000) / (1800.0 / LENG);
    tintColor = mix(SkyCol[int(phase)], SkyCol[int(phase) + 1], phase - float(int(phase)));
  }
  if(worldTime >= 22200 && worldTime < 24000) {
    float phase = float(24000 - worldTime) / (1800.0 / LENG);
    tintColor = mix(SkyCol[int(phase)], SkyCol[int(phase) + 1], phase - float(int(phase)));
  }
  tintColor = mix(tintColor, vec3(15.0, 15.0, 15.0), rainStrength);
  return tintColor;
}

vec3 getCloudColor(int worldTime){
  vec3 tintColor = vec3(0,0,0);
  if(worldTime >= 0 && worldTime < 12000 || worldTime == 24000) tintColor = cloudCol[0];
  if(worldTime >= 13800 && worldTime < 22200) tintColor = cloudCol[6];
  if(worldTime >= 12000 && worldTime < 13800) {
    float phase = float(worldTime - 12000) / (1800.0 / LENG);
    tintColor = mix(cloudCol[int(phase)], cloudCol[int(phase) + 1], phase - float(int(phase)));
  }
  if(worldTime >= 22200 && worldTime < 24000) {
    float phase = float(24000 - worldTime) / (1800.0 / LENG);
    tintColor = mix(cloudCol[int(phase)], cloudCol[int(phase) + 1], phase - float(int(phase)));
  }
  tintColor = mix(tintColor, vec3(30.0, 30.0, 30.0), rainStrength);
  return tintColor;
}
