// uniform samplers
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform float rainStrength;

// definitions just for convinient(?)
#define GCOLOROUT     gl_FragData[0]
#define GDEPTHOUT     gl_FragData[1]
#define GNORMALOUT    gl_FragData[2]

vec3 SkyCol[7] = vec3[7]( // overall sky albedo (doesn't look good, needs improvements)
  vec3(38,104,188), // day
  vec3(234,160,117),
  vec3(251,143,92),
  vec3(251,82,48),
  vec3(147,63,58),
  vec3(43,23,68),
  vec3(15,15,15) // night
  );

vec3 cloudCol[7] = vec3[7]( // cloud albedo, only used when cloud rendering is enabled
  vec3(255,255,255), // day
  vec3(251,180,3),
  vec3(251,180,3),
  vec3(255,113,68),
  vec3(152,85,128),
  vec3(60,60,60),
  vec3(30,30,30) // night
  );

// SkyCol and cloudCol must share the same length

#define LENG 6 // must be (SkyCol.length - 1)

vec3 getAlbedo(in vec2 coord){
  return texture2D(gcolor, coord).rgb;
}

vec3 getNormal(in vec2 coord){
  return texture2D(gnormal, coord).rgb * 2.0 - 1.0;
}

float getEmission(in vec2 coord){
  return texture2D(gdepth, coord).a;
}

float getTorchLight(in vec2 coord){ // get lightmap
  return texture2D(gdepth, coord).r;
}

float getSkyLight(in vec2 coord){ // get lightmap
  return texture2D(gdepth, coord).g;
}

float getTerrain(in vec2 coord){ // get block identity (why did I call it getTerrain?)
  return texture2D(gdepth, coord).b;
}

vec3 getSkyColor(int worldTime){ // inputs worldTime and outputs the albedo for sky
  vec3 tintColor = vec3(0,0,0);

  if(worldTime >= 0 && worldTime < 12000 || worldTime == 24000) tintColor = SkyCol[0]; // day

  if(worldTime >= 13800 && worldTime < 22200) tintColor = SkyCol[6]; // night

  if(worldTime >= 12000 && worldTime < 13800) { // sunset
    float phase = float(worldTime - 12000) / (1800.0 / LENG);
    tintColor = mix(SkyCol[int(phase)], SkyCol[int(phase) + 1], phase - float(int(phase)));
  }

  if(worldTime >= 22200 && worldTime < 24000) { // sunrise (I love this)
    float phase = float(24000 - worldTime) / (1800.0 / LENG);
    tintColor = mix(SkyCol[int(phase)], SkyCol[int(phase) + 1], phase - float(int(phase)));
  }

  tintColor = mix(tintColor, vec3(15.0, 15.0, 15.0), rainStrength); // rain effects
  return tintColor;
}

vec3 getCloudColor(int worldTime){ // basically the same as "getSkyColor(int worldTime)"
  vec3 tintColor = vec3(0,0,0);

  if(worldTime >= 0 && worldTime < 12000 || worldTime == 24000) tintColor = cloudCol[0]; // day

  if(worldTime >= 13800 && worldTime < 22200) tintColor = cloudCol[6]; // night

  if(worldTime >= 12000 && worldTime < 13800) { // sunset
    float phase = float(worldTime - 12000) / (1800.0 / LENG);
    tintColor = mix(cloudCol[int(phase)], cloudCol[int(phase) + 1], phase - float(int(phase)));
  }

  if(worldTime >= 22200 && worldTime < 24000) { // sunrise
    float phase = float(24000 - worldTime) / (1800.0 / LENG);
    tintColor = mix(cloudCol[int(phase)], cloudCol[int(phase) + 1], phase - float(int(phase)));
  }

  tintColor = mix(tintColor, vec3(30.0, 30.0, 30.0), rainStrength); // rain effects (doesn't work well?)
  return tintColor;
}
