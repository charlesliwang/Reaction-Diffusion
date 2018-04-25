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


vec3 noise_gen3D(vec3 pos) {
    float x = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(12.9898, 78.233, 78.156))) * 43758.5453);
    float y = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(2.332, 14.5512, 170.112))) * 78458.1093);
    float z = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(400.12, 90.5467, 10.222))) * 90458.7764);
    return 2.0 * (vec3(x,y,z) - 0.5);
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
