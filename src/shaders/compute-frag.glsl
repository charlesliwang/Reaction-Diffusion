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


float laplaceA(vec2 uv) {
	float sumA = 0.0;
	// sumA += texture(u_input, uv)[0] * -1.0;
	// sumA += texture(u_input, uv + vec2(-x,0.0))[0] * 0.2;
	// sumA += texture(u_input, uv + vec2(x,0.0))[0] * 0.2;
	// sumA += texture(u_input, uv + vec2(0.0, -y))[0] * 0.2;
	// sumA += texture(u_input, uv + vec2(0.0, y))[0] * 0.2;
	// sumA += texture(u_input, uv + vec2(-x, -y))[0] * 0.05;
	// sumA += texture(u_input, uv + vec2(x, y))[0] * 0.05;
	// sumA += texture(u_input, uv + vec2(-x, y))[0] * 0.05;
	// sumA += texture(u_input, uv + vec2(x, -y))[0] * 0.05;

	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,0), 0).x * -1.0;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,-1), 0).x * 0.2;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,1), 0).x * 0.2;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,0), 0).x * 0.2;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,0), 0).x * 0.2;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,-1), 0).x * 0.05;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,-1), 0).x * 0.05;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,1), 0).x * 0.05;
	sumA += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,1), 0).x * 0.05;
	return sumA;
}

float laplaceB(vec2 uv) {
	float sumB = 0.0;
	// sumB += texture(u_input, uv)[1] * -1.0;
	// sumB += texture(u_input, uv + vec2(-x,0.0))[1] * 0.2;
	// sumB += texture(u_input, uv + vec2(x,0.0))[1] * 0.2;
	// sumB += texture(u_input, uv + vec2(0.0, -y))[1] * 0.2;
	// sumB += texture(u_input, uv + vec2(0.0, y))[1] * 0.2;
	// sumB += texture(u_input, uv + vec2(-x, -y))[1] * 0.05;
	// sumB += texture(u_input, uv + vec2(x, y))[1] * 0.05;
	// sumB += texture(u_input, uv + vec2(-x, y))[1] * 0.05;
	// sumB += texture(u_input, uv + vec2(x, -y))[1] * 0.05;

	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,0), 0).y * -1.0;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,-1), 0).y * 0.2;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(0,1), 0).y * 0.2;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,0), 0).y * 0.2;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,0), 0).y * 0.2;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,-1), 0).y * 0.05;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,-1), 0).y * 0.05;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(-1,1), 0).y * 0.05;
	sumB += texelFetch(u_input, ivec2(gl_FragCoord.xy) + ivec2(1,1), 0).y * 0.05;
	return sumB;
}

void main() { 

	float dA = 1.0;
	float dB = 0.5;
	float feed = 0.0545;
	float k = 0.062;
	ivec2 frag_coord = ivec2(gl_FragCoord.xy);
	vec4 input_u = texture(u_input, fs_UV);
	input_u = texelFetch(u_input, frag_coord, 0);
	float a = input_u.x;
	float b = input_u.y;
	float next_a = 0.0;
	next_a = a + ((dA * laplaceA(fs_UV)) - (a * b * b) + (feed * (1.0 - a )) ) * 1.;
	float next_b = 0.0;
	next_b = b + (dB * laplaceB(fs_UV) + (a * b * b) - (k + feed) * b) * 1.;
	next_a = clamp(next_a, 0.0, 1.0);
	next_b = clamp(next_b, 0.0, 1.0);
	// a += 0.01;
	// b += 0.01;
	// if(a > 1.0) {
	// 	a = 0.0;
	// }
	// if(b > 1.0) {
	// 	b = 0.0;
	// }
	
	vec3 col = vec3(next_a,next_b,0.0);
	if(int(gl_FragCoord.x) == 0 || int(gl_FragCoord.y) == 0 || int(frag_coord.x) > (u_Width - 3) || int(frag_coord.y) > (u_Height - 3)) {
		col = vec3(a,b,0.0);
	}
	//col = texelFetch(u_input, frag_coord, 0).xyz;
	//col = vec3(u_Height/u_Width, 0.0,0.0);
	if(u_MouseCount > 0.0 && distance(u_Mouse,gl_FragCoord.xy) < 40.0) {
		col = vec3(1,1,0);
	}
	out_Col = vec4(col, 1.0);
}