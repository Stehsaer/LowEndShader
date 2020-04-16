vec2 celshadeoffset[12] = vec2[12](vec2(-2.0,2.0),vec2(-1.0,2.0),vec2(0.0,2.0),vec2(1.0,2.0),vec2(2.0,2.0),vec2(-2.0,1.0),vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(2.0,1.0),vec2(1.0,0.0),vec2(2.0,0.0));

float blackoutline(sampler2D depth, float forcefull){
	float ph = 1.0/1080.0;
	float pw = ph/aspectRatio;

	float outline = 1.0;
	float z = ld(texture2D(depth,texcoord.xy).r)*far*2.0;
	float minz = far;
	float sampleza = 0.0;
	float samplezb = 0.0;

	#ifdef Fog
	float dist = FogRange*8.0*(1.0+sunVisibility)/(0.75*rainStrength+0.25);
	if (isEyeInWater > 0.5) dist = wfogrange*(1.5*eBS+1.5);
	#else
	float dist = 4096.0;
	#endif

	for (int i = 0; i < 12; i++){
		sampleza = ld(texture2D(depth,texcoord.xy+vec2(pw,ph)*celshadeoffset[i]).r)*far;
		samplezb = ld(texture2D(depth,texcoord.xy-vec2(pw,ph)*celshadeoffset[i]).r)*far;
		outline *= clamp(1.0-(z-(sampleza+samplezb))*0.5,0.0,1.0);
		minz = min(minz,min(sampleza,samplezb));
	}
	outline = mix(outline,1.0,min(minz/dist,clamp(0.8+0.2*isEyeInWater,0.0,1.0))*(1.0-forcefull));

	return outline;
}

float celshademask(sampler2D depth0, sampler2D depth1){
	float ph = 1.0/540.0;
	float pw = ph/aspectRatio;

	float mask = 0.0;
	for (int i = 0; i < 12; i++){
		mask += float(texture2D(depth0,texcoord.xy+vec2(pw,ph)*celshadeoffset[i]).r < texture2D(depth1,texcoord.xy+vec2(pw,ph)*celshadeoffset[i]).r);
		mask += float(texture2D(depth0,texcoord.xy-vec2(pw,ph)*celshadeoffset[i]).r < texture2D(depth1,texcoord.xy-vec2(pw,ph)*celshadeoffset[i]).r);
	}

	return clamp(mask,0.0,1.0);
}

vec2 promooutlineoffset[4] = vec2[4](vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(1.0,0.0));

float promooutline(sampler2D depth){
	float ph = 1.0/1080.0;
	float pw = ph/aspectRatio;

	float outlinec = 1.0;
	float z = ld(texture2D(depth,texcoord.xy).r)*far;
	float totalz = 0.0;
	float maxz = 0.0;
	float sampleza = 0.0;
	float samplezb = 0.0;

	for (int i = 0; i < 4; i++){
		sampleza = ld(texture2D(depth,texcoord.xy+vec2(pw,ph)*promooutlineoffset[i]).r)*far;
		maxz = max(sampleza,maxz);

		samplezb = ld(texture2D(depth,texcoord.xy-vec2(pw,ph)*promooutlineoffset[i]).r)*far;
		maxz = max(samplezb,maxz);

		outlinec*= clamp(1.0-((sampleza+samplezb)-z*2.0)*32.0/z,0.0,1.0);

		totalz += sampleza+samplezb;
	}
	float outlinea = 1.0-clamp((z*8.0-totalz)*64.0-0.08*z,0.0,1.0)*(clamp(1.0-(z*8.0-totalz)*16.0/z,0.0,1.0));
	float outlineb = clamp(1.0+32.0*(z-maxz)/z,0.0,1.0);
	float outline = (0.25*(outlinea*outlineb)+0.75)*(0.75*(1.0-outlinec)*outlineb+1.0);
	return outline;
}
