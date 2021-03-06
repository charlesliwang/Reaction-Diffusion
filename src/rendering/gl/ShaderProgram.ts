import {vec2, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import Texture from './Texture';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;
  attrUV: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifView: WebGLUniformLocation;
  unifProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifWidth: WebGLUniformLocation;
  unifHeight: WebGLUniformLocation;
  unifMouse: WebGLUniformLocation;
  unifMouseCount: WebGLUniformLocation;
  unifMouseRadius: WebGLUniformLocation;
  unifReactionVars: WebGLUniformLocation;
  unifReactionMode: WebGLUniformLocation;
  unifDiffuseDir: WebGLUniformLocation;
  unifNoiseTransform: WebGLUniformLocation;
  unifMouseDiffuseDir : WebGLUniformLocation;


	gb0: WebGLUniformLocation; // The handle of a sampler2D in our shader which samples the texture drawn to the quad

  unifTexUnits: Map<string, WebGLUniformLocation>;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.attrUV = gl.getAttribLocation(this.prog, "vs_UV");
    this.unifModel = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifView = gl.getUniformLocation(this.prog, "u_View");
    this.unifProj = gl.getUniformLocation(this.prog, "u_Proj");
    this.unifColor = gl.getUniformLocation(this.prog, "u_Color");
    this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
    this.unifWidth = gl.getUniformLocation(this.prog, "u_Width");
    this.unifHeight = gl.getUniformLocation(this.prog, "u_Height");
    this.unifMouse = gl.getUniformLocation(this.prog, "u_Mouse");
    this.unifMouseCount = gl.getUniformLocation(this.prog, "u_MouseCount");
    this.unifMouseDiffuseDir = gl.getUniformLocation(this.prog, "u_MouseDiffuseDir");

    this.unifReactionVars = gl.getUniformLocation(this.prog, "u_ReactionVars");
    this.unifReactionMode = gl.getUniformLocation(this.prog, "u_ReactionMode");
    this.unifDiffuseDir = gl.getUniformLocation(this.prog, "u_DiffuseDir");
    this.unifMouseRadius = gl.getUniformLocation(this.prog, "u_MouseRadius");
    this.unifNoiseTransform = gl.getUniformLocation(this.prog, "u_NoiseTransform");

    //this.use();
    /*this.gb0 = gl.getUniformLocation(this.prog, "u_gb0");
		gl.uniform1i(this.gb0, 1); // gl.TEXTURE0*/

    this.unifTexUnits = new Map<string, WebGLUniformLocation>();
  }

  setupTexUnits(handleNames: Array<string>) {
    for (let handle of handleNames) {
      var location = gl.getUniformLocation(this.prog, handle);
      if (location !== -1) {
        this.unifTexUnits.set(handle, location);
      } else {
        console.log("Could not find handle for texture named: \'" + handle + "\'!");
      }
    }
  }

  // Bind the given Texture to the given texture unit
  bindTexToUnit(handleName: string, tex: Texture, unit: number) {
    this.use();
    var location = this.unifTexUnits.get(handleName);
    if (location !== undefined && location != null) {
      gl.activeTexture(gl.TEXTURE0 + unit);
      tex.bindTex();
      gl.uniform1i(location, unit);
    } else {
      //console.log("Texture with handle name: \'" + handleName + "\' was not found");
    }
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setViewMatrix(vp: mat4) {
    this.use();
    if (this.unifView !== -1) {
      gl.uniformMatrix4fv(this.unifView, false, vp);
    }
  }

  setProjMatrix(vp: mat4) {
    this.use();
    if (this.unifProj !== -1) {
      gl.uniformMatrix4fv(this.unifProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setReactionVars(vars: vec4) {
    this.use();
    if (this.unifReactionVars !== -1) {
      gl.uniform4fv(this.unifReactionVars, vars);
    }
  }

  setReactionMode(mode: number) {
    this.use();
    if (this.unifReactionMode !== -1) {
      gl.uniform1i(this.unifReactionMode, mode);
    }
  }

  setDiffuseDir(vars: vec4) {
    this.use();
    if (this.unifDiffuseDir !== -1) {
      gl.uniform4fv(this.unifDiffuseDir, vars);
    }
  }

  setMousePos(xy: vec2) {
    this.use();
    if (this.unifMouse !== -1) {
      gl.uniform2fv(this.unifMouse, xy);
    }
  }

  setMouseCount(t: number) {
    this.use();
    if (this.unifMouseCount !== -1) {
      gl.uniform1f(this.unifMouseCount, t);
    }
  }

  setMouseRadius(t: number) {
    this.use();
    if (this.unifMouseRadius !== -1) {
      gl.uniform1f(this.unifMouseRadius, t);
    }
  }

  setNoiseTransforms(vars: vec4) {
    this.use();
    if (this.unifNoiseTransform !== -1) {
      gl.uniform4fv(this.unifNoiseTransform, vars);
    }
  }

  setMouseDiffuseDir(vars: vec4) {
    this.use();
    if (this.unifMouseDiffuseDir !== -1) {
      gl.uniform4fv(this.unifMouseDiffuseDir, vars);
    }
  }

  setTime(t: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, t);
    }
  }

  

  setHeight(t: number) {
    this.use();
    if (this.unifHeight !== -1) {
      gl.uniform1i(this.unifHeight, t);
    }
  }

  setWidth(t: number) {
    this.use();
    if (this.unifWidth !== -1) {
      gl.uniform1i(this.unifWidth, t);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrCol != -1 && d.bindCol()) {
      gl.enableVertexAttribArray(this.attrCol);
      gl.vertexAttribPointer(this.attrCol, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrUV != -1 && d.bindUV()) {
      gl.enableVertexAttribArray(this.attrUV);
      gl.vertexAttribPointer(this.attrUV, 2, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
    if (this.attrCol != -1) gl.disableVertexAttribArray(this.attrCol);
    if (this.attrUV != -1) gl.disableVertexAttribArray(this.attrUV);
  }
};

export default ShaderProgram;
