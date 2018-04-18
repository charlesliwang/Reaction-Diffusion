#version 300 es
precision highp float;

#define NUM_ROWS 200.0
#define NUM_COLS 400.0

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_input;
uniform float u_Time;



vec3 noise_gen3D(vec3 pos) {
    float x = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(12.9898, 78.233, 78.156))) * 43758.5453);
    float y = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(2.332, 14.5512, 170.112))) * 78458.1093);
    float z = fract(sin(dot(vec3(pos.x,pos.y,pos.z), vec3(400.12, 90.5467, 10.222))) * 90458.7764);
    return 2.0 * (vec3(x,y,z) - 0.5);
}

// Interpolation between color and greyscale over time on left half of screen
void main() {

	vec2 size = vec2(2.0,0.0);
 	ivec3 off = ivec3(-1,0,1);

	vec4 gb1 = texture(u_input, fs_UV);

	gb1 = texelFetch(u_input, ivec2(gl_FragCoord.xy), 0);
	float c = (gb1.x - gb1.y);

    float s11 = c;
    vec2 s01xy = texelFetch(u_input, ivec2(gl_FragCoord.xy) + off.xy, 0).xy;
    vec2 s21xy = texelFetch(u_input, ivec2(gl_FragCoord.xy) + off.zy, 0).xy;
    vec2 s10xy = texelFetch(u_input, ivec2(gl_FragCoord.xy) + off.yx, 0).xy;
    vec2 s12xy = texelFetch(u_input, ivec2(gl_FragCoord.xy) + off.yz, 0).xy;
	float s01 = s01xy.x - s01xy.y;
	float s21 = s21xy.x - s21xy.y;
	float s10 = s10xy.x - s10xy.y;
	float s12 = s12xy.x - s12xy.y;
    vec3 va = normalize(vec3(size.xy,s21-s01));
    vec3 vb = normalize(vec3(size.yx,s12-s10));
    vec4 bump = vec4( cross(va,vb), s11 );
	
	float d = dot(bump.xyz,normalize(vec3(1,-1,0.5)));
	d = clamp(d,0.0,1.0);

	vec3 col = mix(vec3(1,0,0), vec3(0,0,1), d);
	
	out_Col = vec4(bump.xyz, 1.0);
	out_Col = vec4(col,1.0);
	//out_Col = vec4(col,1.0);
}
