#version 300 es
precision highp float;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec2 fs_UV;

in vec4 ws_Nor;
in vec4 ss_Nor;

uniform sampler2D u_gb0;
uniform float u_Time;

out vec4 fragColor[3]; // The data in the ith index of this array of outputs
                       // is passed to the ith index of OpenGLRenderer's
                       // gbTargets array, which is an array of textures.
                       // This lets us output different types of data,
                       // such as albedo, normal, and position, as
                       // separate images from a single render pass.

uniform sampler2D tex_Color;


void main() {
    // TODO: pass proper data into gbuffers
    // Presently, the provided shader passes "nothing" to the first
    // two gbuffers and basic color to the third.

    vec3 col = texture(tex_Color, fs_UV).rgb;

    // if using textures, inverse gamma correct
    col = pow(col, vec3(2.2));
    
    float z = 0.0;
    // if(fs_Pos.z > 100.0) {
    //     z = 1.0;
    // }l

	vec4 gb0 = texture(u_gb0, fs_UV);
    if(u_Time < 1.0) {
        gb0 = vec4(1.0,0.0,0.0,1.0);
    }
    vec3 rgb = gb0.xyz + vec3(0.05,0.05,0.05);
    // if(rgb.x > 1.0) {
    //     rgb = vec3(0.0);
    // }

    fragColor[0] = vec4(gb0.xyz, 1.0);
    fragColor[1] = vec4(rgb, 1.0);
    fragColor[2] = vec4(col, 1.0);
}
