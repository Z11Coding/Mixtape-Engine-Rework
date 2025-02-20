#pragma header

uniform vec2 u_samples; // careful!! O(xy) time
uniform vec2 u_size;

uniform float u_brightness;
uniform vec3 u_tint;
uniform float u_threshold;
uniform float u_range;

float lstep(float edge_0, float edge_1, float x) {
	return clamp((x - edge_0) / (edge_1 - edge_0), 0.0, 1.0);
}

vec4 bloom_pass(vec2 uv) {
	vec2 texel = 7.0 / openfl_TextureSize;
	
	vec2 samples = max(u_samples, vec2(2.0, 2.0));
	vec4 color = vec4(0.0);
	float total = 0.0;
	for (float x = -0.5; x <= 0.5; x += 1.0 / samples.x) {
		for (float y = -0.5; y <= 0.5; y += 1.0 / samples.y) {
			vec2 offs = vec2(x, y);
			vec4 tex = flixel_texture2D(bitmap, uv + offs * texel * u_size);
			float weight = length(tex.rgb);
			
			float luminance = dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722));
			luminance = lstep(u_threshold - u_range, u_threshold + u_range, luminance);
			tex *= luminance;
			
			color += tex * weight * pow(max(1.0 - length(offs * 5.0), 5.0), 5.0);
			total += weight;
		}
	}

	return color / total;
}

void main() {
	vec2 uv = openfl_TextureCoordv;
	
	vec4 tex = flixel_texture2D(bitmap, uv);
	vec4 bloom = vec4(0.0);
	if (u_brightness > 0.0) {
		bloom = bloom_pass(uv) * 10.0;
		bloom.rgb *= u_tint * u_brightness;
	}
	
	gl_FragColor = tex + bloom;
	gl_FragColor.a = tex.a;
}