uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform float rainStrength;

#define GCOLOROUT     gl_FragData[0]
#define GDEPTHOUT     gl_FragData[1]
#define GNORMALOUT    gl_FragData[2]

vec3 SkyCol[7] = vec3[7](
  vec3(137,202,234),
  vec3(234,160,117),
  vec3(251,143,92),
  vec3(251,82,48),
  vec3(147,63,58),
  vec3(43,23,68),
  vec3(15,15,15)
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
  if(worldTime >= 13800 && worldTime < 22200) tintColor = SkyCol[5];
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
