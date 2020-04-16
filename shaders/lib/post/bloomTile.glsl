vec3 bloomTile(float lod, vec2 offset){
	vec3 bloom = vec3(0.0);
	float scale = pow(2.0,lod);
	vec2 coord = (texcoord.xy-offset)*scale;
	float padding = 0.005*scale;

	if (coord.x > -padding && coord.y > -padding && coord.x < 1.0+padding && coord.y < 1.0+padding){
		for (int i = -3; i <= 3; i++) {
			for (int j = -3; j <= 3; j++) {
			float wg = clamp(1.0-length(vec2(i,j))*0.28,0.0,1.0);
			wg = wg*wg*20.0;
			vec2 bcoord = (texcoord.xy-offset+vec2(i,j)*vec2(pw,ph))*scale;
			if (wg > 0){
				bloom += texture2D(colortex0,bcoord).rgb*wg;
				}
			}
		}
		bloom /= 49;
	}

	return pow(bloom/128.0,vec3(0.25));
}