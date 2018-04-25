#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_input;

uniform float u_Time;
uniform int u_Width;
uniform int u_Height;

uniform mat4 u_View;
uniform vec4 u_CamPos;   

uniform vec2 u_Mouse;
uniform float u_MouseCount;
uniform float u_MouseRadius;
uniform vec4 u_MouseDiffuseDir;

uniform int u_ReactionMode;
uniform vec4 u_ReactionVars;
uniform vec4 u_DiffuseDir;
uniform vec4 u_NoiseTransform;



float fade (float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); 
}

vec3 noise_gen3D(vec3 pos) {
    float x = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(12.9898, 78.233, 78.156))) * 43758.5453);
    float y = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(2.332, 14.5512, 170.112))) * 78458.1093);
    float z = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(400.12, 90.5467, 10.222))) * 90458.7764);
    return 2.0 * (vec3(x,y,z) - 0.5);
}

float dotGridGradient(vec3 grid, vec3 pos) {
    vec3 grad = normalize(noise_gen3D(grid));
    vec3 diff = (pos - grid);
    //return grad.x;
    return clamp(dot(grad,diff),-1.0,1.0);
}

float perlin3D(vec3 pos, float step) {
    pos = pos/step;
    vec3 ming = floor(pos / step) * step;
    ming = floor(pos);
    vec3 maxg = ming + vec3(step, step, step);
    maxg = ming + vec3(1.0);
    vec3 range = maxg - ming;
    vec3 diff = pos - ming;
    vec3 diff2 = maxg - pos;
    float d000 = dotGridGradient(ming, pos);
    float d001 = dotGridGradient(vec3(ming[0], ming[1], maxg[2]), pos);
    float d010 = dotGridGradient(vec3(ming[0], maxg[1], ming[2]), pos);
    float d011 = dotGridGradient(vec3(ming[0], maxg[1], maxg[2]), pos);
    float d111 = dotGridGradient(vec3(maxg[0], maxg[1], maxg[2]), pos);
    float d100 = dotGridGradient(vec3(maxg[0], ming[1], ming[2]), pos);
    float d101 = dotGridGradient(vec3(maxg[0], ming[1], maxg[2]), pos);
    float d110 = dotGridGradient(vec3(maxg[0], maxg[1], ming[2]), pos);

    float ix00 = mix(d000,d100, fade(diff[0]));
    float ix01 = mix(d001,d101, fade(diff[0]));
    float ix10 = mix(d010,d110, fade(diff[0]));
    float ix11 = mix(d011,d111, fade(diff[0]));

    float iy0 = mix(ix00, ix10, fade(diff[1]));
    float iy1 = mix(ix01, ix11, fade(diff[1]));

    float iz = mix(iy0, iy1, fade(diff[2]));

    return (iz + 1.0) / 2.0;
}

float getDirScale(int x, int y) {
	vec2 dir = u_DiffuseDir.xy;
	if(int(u_DiffuseDir.w) == 0) {
		return 1.0;
	} if(int(u_MouseDiffuseDir.w) == 1) {
		if(int(u_MouseDiffuseDir.z) == 1) {
			dir = u_MouseDiffuseDir.xy - gl_FragCoord.xy;
		}
	}
	return (dot(normalize(dir), vec2(float(x),float(y)))) * u_DiffuseDir.z + 1.0; 
}

float laplaceA() {
	float sumA = 0.0;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,0), 0).x * -1.0 * getDirScale(0,0);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,-1), 0).x * 0.2 * getDirScale(0,-1);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,1), 0).x * 0.2 * getDirScale(0,1);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,0), 0).x * 0.2 * getDirScale(1,0);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,0), 0).x * 0.2 * getDirScale(-1,0);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,-1), 0).x * 0.05 * getDirScale(-1,-1);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,-1), 0).x * 0.05 * getDirScale(1,-1);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,1), 0).x * 0.05 * getDirScale(-1,1);
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,1), 0).x * 0.05 * getDirScale(1,1);
	return sumA;
}

float laplaceB() {
	float sumB = 0.0;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,0), 0).y * -1.0 * getDirScale(0,0);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,-1), 0).y * 0.2 * getDirScale(0,-1);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,1), 0).y * 0.2 * getDirScale(0,1);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,0), 0).y * 0.2 * getDirScale(1,0);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,0), 0).y * 0.2 * getDirScale(-1,0);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,-1), 0).y * 0.05 * getDirScale(-1,-1);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,-1), 0).y * 0.05 * getDirScale(1,-1);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,1), 0).y * 0.05 * getDirScale(-1,1);
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,1), 0).y * 0.05 * getDirScale(1,1);
	return sumB;
}

void main() { 

	float dA = 1.0;
	float dB = 0.5;
	float feed = 0.04;
	float k = 0.05;
	feed = u_ReactionVars.x;
	k = u_ReactionVars.y;

	if(u_ReactionMode == 1) {
		float feed_norm = mod(fs_UV.x + mod(u_Time / 30.0,120.0)/(120.0),1.0 );
		feed = mix(0.03,0.07, feed_norm);
		float k_norm = mod(fs_UV.x + mod(u_Time / 10.0,120.0)/(120.0),1.0 );
		k = mix(0.05,0.07, k_norm);
	} else if( u_ReactionMode == 2) {
		float t_warpx = sin(PI * mod(u_Time / 30.0, 120.0) / 120.0);
		float feed_norm = mod(fs_UV.x + t_warpx,1.0 );
		feed_norm = mod(fs_UV.x + mod(u_Time / 30.0,120.0)/(120.0),1.0 );
		feed = mix(0.03,0.07, feed_norm);
		float t_warpy = sin(PI * mod(u_Time / 10.0, 120.0) / 120.0);
		float k_norm = mod(fs_UV.y + t_warpy,1.0 );
		k_norm = mod(fs_UV.y + mod(u_Time / 10.0,120.0)/(120.0),1.0 );
		k = mix(0.05,0.07, k_norm);
	} else if( u_ReactionMode == 3) {
		float feed_norm = perlin3D(vec3(gl_FragCoord.xy/100.0/u_NoiseTransform.x, 0), 1.0);
		float k_norm = perlin3D(vec3(gl_FragCoord.xy/100.0/u_NoiseTransform.y + vec2(50.0), 0), 1.0);
		feed = mix(0.03,0.07, feed_norm);
		k = mix(0.05,0.07, k_norm);
	}
	
	ivec2 frag_coord = ivec2(gl_FragCoord.xy);
	//vec4 input_u = texture(u_input, fs_UV);
	vec4 input_u = texelFetch(u_input, frag_coord, 0);
	float a = input_u.x;
	float b = input_u.y;
	float next_a = a + 
		((dA * laplaceA()) 
		- (a * b * b) 
		+ (feed * (1.0 - a)) ) 
		* 1.0;
	float next_b = b 
		+ ((dB * laplaceB()) 
		+ (a * b * b) 
		- ( (k + feed) * b ) ) 
		* 1.0;
	next_a = clamp(next_a, 0.0, 1.0);
	next_b = clamp(next_b, 0.0, 1.0);

	
	vec3 col = vec3(next_a,next_b,0.0);
	if(int(gl_FragCoord.x) == 0 || int(gl_FragCoord.y) == 0 || int(frag_coord.x) > (u_Width - 2) || int(frag_coord.y) > (u_Height - 2)) {
		col = vec3(a,b,0.0);
	}
	//col = texelFetch(u_input, frag_coord, 0).xyz;
	//col = vec3(u_Height/u_Width, 0.0,0.0);
	if(u_MouseCount > 0.0 && distance(u_Mouse,gl_FragCoord.xy) < u_MouseRadius) {
		col = vec3(1.0,1.0,0);
	}
	// col = vec3(laplaceA(),laplaceB(),0.0);
	// col = (col + vec3(1.0))/2.0;
	// col = vec3(1.0);
	out_Col = vec4(col, 1.0);
}