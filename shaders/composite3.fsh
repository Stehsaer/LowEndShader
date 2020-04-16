#version 120

// original final.fsh
// for sun flares and tone mappings

uniform sampler2D gcolor;
uniform sampler2D colortex1;
#define BLOOM
#define SUN_FLARE
#define TONEMAPPING

varying vec4 texcoord;

float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 13.134;

#ifdef SUN_FLARE
uniform float aspectRatio;
uniform float rainStrength;

varying float sunVisibility;
varying vec2 lf1Pos;
varying vec2 lf2Pos;
varying vec2 lf3Pos;
varying vec2 lf4Pos;

#define MANHATTAN_DISTANCE(DELTA) abs(DELTA.x)+abs(DELTA.y)

#define LENS_FLARE(COLOR, UV, LFPOS, LFSIZE, LFCOLOR) { \
                vec2 delta = UV - LFPOS; delta.x *= aspectRatio; \
                if(MANHATTAN_DISTANCE(delta) < LFSIZE * 2.0) { \
                    float d = max(LFSIZE - sqrt(dot(delta, delta)), 0.0); \
                    COLOR += LFCOLOR.rgb * LFCOLOR.a * smoothstep(0.0, LFSIZE, d) * sunVisibility * (1.0 - rainStrength);\
                } }

#define LF1SIZE 0.1
#define LF2SIZE 0.15
#define LF3SIZE 0.25
#define LF4SIZE 0.25

const vec4 LF1COLOR = vec4(1.0, 1.0, 1.0, 0.2);
const vec4 LF2COLOR = vec4(0.42, 0.0, 1.0, 0.2);
const vec4 LF3COLOR = vec4(0.0, 1.0, 0.0, 0.2);
const vec4 LF4COLOR = vec4(1.0, 0.0, 0.0, 0.2);

vec3 lensFlare(vec3 color, vec2 uv) {
    if(sunVisibility <= 0.0)
        return color;
    LENS_FLARE(color, uv, lf1Pos, LF1SIZE, LF1COLOR);
    LENS_FLARE(color, uv, lf2Pos, LF2SIZE, LF2COLOR);
    LENS_FLARE(color, uv, lf3Pos, LF3SIZE, LF3COLOR);
    LENS_FLARE(color, uv, lf4Pos, LF4SIZE, LF4COLOR);
    return color;
}

#endif

vec3 uncharted2Tonemap(vec3 x) {
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

void main() {
    vec3 color =  texture2D(gcolor, texcoord.st).rgb;
    #ifdef BLOOM
    vec3 highlight = texture2D(colortex1, texcoord.st).rgb;
    color = color + highlight;
    #endif

    #ifdef TONEMAPPING
    color = pow(color, vec3(1.4));
    color *= 5.0;
    vec3 curr = uncharted2Tonemap(color);
    vec3 whiteScale = 1.0f / uncharted2Tonemap(vec3(W));
    color = curr * whiteScale;
    #endif


    #ifdef SUN_FLARE
    color = lensFlare(color, texcoord.st);
    #endif

    gl_FragColor = vec4(color, 1.0);
}
