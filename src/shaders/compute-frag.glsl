#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_input;

uniform float u_Time;

uniform mat4 u_View;
uniform vec4 u_CamPos;   


void main() { 
	vec3 lightdir = vec3(1,1,0);
	lightdir = normalize(lightdir);
	
	vec4 input_u = texture(u_input, fs_UV);
	vec3 col = (input_u.xyz) + vec3(0.01);
	if(input_u.x > 1.0) {
		col = vec3(0.0);
	}
	out_Col = vec4(col, 1.0);
}