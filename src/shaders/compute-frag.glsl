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

uniform int u_ReactionMode;
uniform vec4 u_ReactionVars;
uniform vec4 u_DiffuseDir;

float getDirScale(int x, int y) {
	if(int(u_DiffuseDir.w) == 0) {
		return 1.0;
	}
	return (dot(u_DiffuseDir.xy, vec2(float(x),float(y)))) * u_DiffuseDir.z + 1.0; 
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
	if(u_MouseCount > 0.0 && distance(u_Mouse,gl_FragCoord.xy) < 40.0) {
		col = vec3(1.0,1.0,0);
	}
	// col = vec3(laplaceA(),laplaceB(),0.0);
	// col = (col + vec3(1.0))/2.0;
	// col = vec3(1.0);
	out_Col = vec4(col, 1.0);
}