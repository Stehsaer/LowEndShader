uniform sampler2DShadow shadowtex0;
#ifdef ShadowColor
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

/*
uniform sampler2D shadowtex0;
#ifdef ShadowColor
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif
*/

vec2 shadowoffsets[8] = vec2[8](    vec2( 0.0, 1.0),
                                    vec2( 0.7, 0.7),
                                    vec2( 1.0, 0.0),
                                    vec2( 0.7,-0.7),
                                    vec2( 0.0,-1.0),
                                    vec2(-0.7,-0.7),
                                    vec2(-1.0, 0.0),
                                    vec2(-0.7, 0.7));

float texture2DShadow(sampler2D shadowtex, vec3 shadowpos){
    float shadow = texture2D(shadowtex,shadowpos.st).x;
    shadow = clamp((shadow-shadowpos.z)*65536.0,0.0,1.0);
    return shadow;
}

vec2 offsetDist(float x, int s){
	float n = fract(x*1.414)*3.1415;
    return vec2(cos(n),sin(n))*1.4*x/s;
}

float getBasicShadow(vec3 shadowpos){
    return shadow2D(shadowtex0,vec3(shadowpos.st, shadowpos.z)).x;
    //return texture2DShadow(shadowtex0,vec3(shadowpos.st, shadowpos.z));
}

float getFilteredShadow(vec3 shadowpos, float step){
    float shadow = getBasicShadow(vec3(shadowpos.st, shadowpos.z))*2.0;

    for(int i = 0; i < 8; i++){
        shadow+= getBasicShadow(vec3(step * shadowoffsets[i] + shadowpos.st, shadowpos.z));
    }

    return shadow * 0.1;
}

float getTAAFilteredShadow(vec3 shadowpos, float step){
    float noise = gradNoise();

    float shadow = 0.0;

    for(int i = 0; i < 2; i++){
        vec2 offset = offsetDist(noise+i,2)*step;
        shadow += getBasicShadow(vec3(shadowpos.st+offset, shadowpos.z));
        shadow += getBasicShadow(vec3(shadowpos.st-offset, shadowpos.z));
    }
    
    return shadow * 0.25;
}

#ifdef ShadowColor
vec3 getBasicShadowColor(vec3 shadowpos){
    return texture2D(shadowcolor0,shadowpos.st).rgb*shadow2D(shadowtex1,vec3(shadowpos.st, shadowpos.z)).x;
    //return texture2D(shadowcolor0,shadowpos.st).rgb*texture2DShadow(shadowtex1,vec3(shadowpos.st, shadowpos.z));
}

vec3 getFilteredShadowColor(vec3 shadowpos, float step){
    vec3 shadowcol = getBasicShadowColor(vec3(shadowpos.st, shadowpos.z))*2.0;

    for(int i = 0; i < 8; i++){
        shadowcol+= getBasicShadowColor(vec3(step * shadowoffsets[i] + shadowpos.st, shadowpos.z));
    }

    return shadowcol * 0.1;
}

vec3 getTAAFilteredShadowColor(vec3 shadowpos, float step){
    float noise = gradNoise()*3.14;
    vec2 rot = vec2(cos(noise),sin(noise))*step;

    vec3 shadowcol = getBasicShadowColor(vec3(shadowpos.st+rot, shadowpos.z));
         shadowcol+= getBasicShadowColor(vec3(shadowpos.st-rot, shadowpos.z));
         shadowcol+= getBasicShadowColor(vec3(shadowpos.st+rot*0.5, shadowpos.z));
         shadowcol+= getBasicShadowColor(vec3(shadowpos.st-rot*0.5, shadowpos.z));
    return shadowcol * 0.25;
}
#endif

vec3 getShadow(vec3 shadowpos, float step){
    vec3 shadowcol = vec3(0.0);

    #ifdef ShadowFilter
    #if AA == 2
    float shadow = getTAAFilteredShadow(shadowpos, step);
    #else
    float shadow = getFilteredShadow(shadowpos, step);
    #endif
    #else
    float shadow = getBasicShadow(shadowpos);
    #endif

    #ifdef ShadowColor
    if(shadow < 0.999){
        #ifdef ShadowFilter
        #if AA == 2
        shadowcol = getTAAFilteredShadowColor(shadowpos, step);
        #else
        shadowcol = getFilteredShadowColor(shadowpos, step);
        #endif
        #else
        shadowcol = getBasicShadowColor(shadowpos);
        #endif
    }
    #endif

    return max(vec3(shadow), shadowcol);
}