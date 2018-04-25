#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_input;
uniform float u_Time;

uniform int u_ReactionMode;
uniform vec4 u_ReactionVars;
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

// Interpolation between color and greyscale over time on left half of screen
void main() {
	float feed = u_ReactionVars.x;
	float k = u_ReactionVars.y;
	float k_norm = 0.0;
	float feed_norm = 0.0;

	if(u_ReactionMode == 0) {
		feed_norm = u_ReactionVars.x/0.1;
		k_norm = u_ReactionVars.y/0.1;
	} else if(u_ReactionMode == 1) {
		feed_norm = mod(fs_UV.x + mod(u_Time / 30.0,120.0)/(120.0),1.0 );
		feed = mix(0.03,0.07, feed_norm);
		k_norm = mod(fs_UV.x + mod(u_Time / 10.0,120.0)/(120.0),1.0 );
		k = mix(0.05,0.07, k_norm);
	} else if( u_ReactionMode == 2) {
		float t_warpx = sin(PI * mod(u_Time / 30.0, 120.0) / 120.0);
		feed_norm = mod(fs_UV.x + t_warpx,1.0 );
		feed_norm = mod(fs_UV.x + mod(u_Time / 30.0,120.0)/(120.0),1.0 );
		feed = mix(0.03,0.07, feed_norm);
		float t_warpy = sin(PI * mod(u_Time / 10.0, 120.0) / 120.0);
		k_norm = mod(fs_UV.y + t_warpy,1.0 );
		k_norm = mod(fs_UV.y + mod(u_Time / 10.0,120.0)/(120.0),1.0 );
		k = mix(0.05,0.07, k_norm);
	} else if( u_ReactionMode == 3) {
		feed_norm = perlin3D(vec3(gl_FragCoord.xy/100.0/u_NoiseTransform.x, 0), 1.0);
		k_norm = perlin3D(vec3(gl_FragCoord.xy/100.0/u_NoiseTransform.y + vec2(5000.0), 0), 1.0);
		feed = mix(0.03,0.07, feed_norm);
		k = mix(0.05,0.07, k_norm);
	}

	vec4 colFeed = mix(vec4(1.0,0.0,0.0,1.0),vec4(0.0,0.0,1.0,1.0), feed_norm);
	vec4 colKill = mix(vec4(0.0,1.0,0.0,1.0),vec4(0.0,0.0,1.0,1.0), k_norm);
	vec4 col = (colFeed + colKill) / 2.0;
	vec2 size = vec2(1.5,0.0);
 	ivec3 off = ivec3(-1,0,1);

	vec4 gb1 = texelFetch(u_input, ivec2(gl_FragCoord.xy), 0);
	float c = (gb1.x - gb1.y);
	c = clamp(c,0.0,1.0);

	out_Col = vec4(c*col.xyz,1.0);
	//out_Col = vec4(col,1.0);
}
