import {vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import Mesh from './geometry/Mesh';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import {readTextFile} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Texture from './rendering/gl/Texture';

// Define an object with application parameters and button callbacks
const controls = {
  'Reset To Default' : resetToDefault,
  shading : 'Grayscale',
  simulationSpeed : 3,
  feedRate: 0.055,
  killRate: 0.062,
  mouseExplosion: true,
  mouseRadius: 40.0,
  mode : 'Constant Feed/Kill Rates',
  diffusionDirection: false,
  diffusionX : 1.0,
  diffusionY : 1.0,
  useMouseClick : false,
  diffusionDirScale : 0.1,
  fNoiseScale: 1.0,
  kNoiseScale: 1.0,
};

let postProcessActive : boolean[] = [true];



let square: Square;

// TODO: replace with your scene's stuff

let obj0: string;
let mesh0: Mesh;

let tex0: Texture;

let flag = true;
let count = 0;

let mouseCount = 0;
let mouseDown = false;
let numIters = 5;

var timer = {
  deltaTime: 0.0,
  startTime: 0.0,
  currentTime: 0.0,
  updateTime: function() {
    var t = Date.now();
    t = (t - timer.startTime) * 0.001;
    timer.deltaTime = t - timer.currentTime;
    timer.currentTime = t;
  },
}

function resetToDefault() {
  controls.feedRate = 0.055;
  controls.killRate = 0.062;
}

function loadOBJText() {
  obj0 = readTextFile('./resources/obj/wahoo.obj')
}


function loadScene() {
  square && square.destroy();
  mesh0 && mesh0.destroy();

  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

  mesh0 = new Mesh(obj0, vec3.fromValues(0, 0, 0));
  mesh0.create();

  tex0 = new Texture('./resources/textures/wahoo.bmp')
}


function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
    // Add controls to the gui
    const gui = new DAT.GUI();
    gui.add(controls, 'Reset To Default');
    const shading = gui.add(controls, 'shading', ['Grayscale', 'Gold Shading', 'f/k Visualization']);
    const simSpeed = gui.add(controls, 'simulationSpeed', 0, 5);
    gui.add(controls, 'feedRate', 0.01, 0.1).listen();
    gui.add(controls, 'killRate', 0.01, 0.1).listen();
    gui.add(controls, 'mouseExplosion', true);
    gui.add(controls, 'mouseRadius', 0.0, 100.0).listen();
    const mode = gui.add(controls, 'mode', ['Constant Feed/Kill Rates', 'Horizontal Waves',
    'x: feed, y: kill', 'Noisy f/k']);
    gui.add(controls, 'diffusionDirection', false);
    let fDiffuse = gui.addFolder('diffusionDirectionControls');
    fDiffuse.add(controls, 'diffusionX', -1.01, 1.01).step(0.01);
    fDiffuse.add(controls, 'diffusionY', -1.01, 1.01).step(0.01);
    let ddmouseclick = fDiffuse.add(controls, 'useMouseClick', false);
    fDiffuse.add(controls, 'diffusionDirScale', 0.0, 1.0);
    let fkNoise = gui.addFolder('f/k Noise Transforms');
    fkNoise.add(controls, 'fNoiseScale');
    fkNoise.add(controls, 'kNoiseScale');

    
  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 9, 25), vec3.fromValues(0, 9, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0, 0, 0, 1);
  gl.enable(gl.DEPTH_TEST);

  const standardDeferred = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/standard-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/standard-frag.glsl')),
    ]);

  const initShader = new ShaderProgram([
      new Shader(gl.VERTEX_SHADER, require('./shaders/init-vert.glsl')),
      new Shader(gl.FRAGMENT_SHADER, require('./shaders/init-frag.glsl')),
      ]);

  standardDeferred.setupTexUnits(["tex_Color"]);

  if(controls.shading == 'Grayscale') {
    renderer.shadingIdx = 0;
  } else if(controls.shading == 'Gold Shading') {
    renderer.shadingIdx = 1;
  } else if(controls.shading == 'f/k Visualization') {
    renderer.shadingIdx = 2;
  } 

  shading.onChange(function() {
      if(controls.shading == 'Grayscale') {
        renderer.shadingIdx = 0;
      } else if(controls.shading == 'Gold Shading') {
        renderer.shadingIdx = 1;
      } else if(controls.shading == 'f/k Visualization') {
        renderer.shadingIdx = 2;
      } 
  });

  mode.onChange(function() {
    if(controls.mode == 'Constant Feed/Kill Rates') {
      renderer.updateRendererReactionMode(0);
    } else if(controls.mode == 'Horizontal Waves') {
      renderer.updateRendererReactionMode(1);
    } else if(controls.mode == 'x: feed, y: kill') {
      renderer.updateRendererReactionMode(2);
    } else if(controls.mode == 'Noisy f/k') {
      renderer.updateRendererReactionMode(3);
    }
  });

  ddmouseclick.onChange(function() {
    if(controls.useMouseClick) {
      renderer.updateMouseDiffuseDir(0,0,0,1);
    }  else {
      renderer.updateMouseDiffuseDir(0,0,0,0);
    }
  });

  

  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    timer.updateTime();
    renderer.updateTime(timer.deltaTime, timer.currentTime);

    standardDeferred.bindTexToUnit("tex_Color", tex0, 0);
    initShader.bindTexToUnit("tex_Color", tex0, 0);

    renderer.clear();
    renderer.clearGB(); // modified
    count++;

    renderer.updateReactionVars(controls.feedRate,controls.killRate,0,0);
    renderer.updateDiffuseDir(controls.diffusionX,controls.diffusionY,controls.diffusionDirScale,Number(controls.diffusionDirection));
    renderer.updateNoiseTransforms(controls.fNoiseScale,controls.kNoiseScale,0,0);
    // if(controls.shading == 'Constant Feed/Kill Rates') {
    //   renderer.setReactionMode(0);
    // } else if(controls.shading == 'Horizontal Waves') {
    //   renderer.setReactionMode(1);
    // }

    // TODO: pass any arguments you may need for shader passes
    // forward render mesh info into gbuffers
    //renderer.renderToGBuffer(camera, standardDeferred, [mesh0]);
    if(count < 10){ 
      initShader.setTime(timer.currentTime);
      initShader.setHeight(window.innerHeight);
      initShader.setWidth(window.innerWidth);
      renderer.initFrameBuffer(camera, initShader, [square]); 
      flag = false;
    }
    // render from gbuffers into 32-bit color buffer
    //renderer.renderFromGBuffer(camera);
    for(let i = 0; i < controls.simulationSpeed; i++) {
      renderer.updateTime(timer.deltaTime,count);
      renderer.updateMouseCount(mouseCount--);
      renderer.renderFromPrev(camera);
      renderer.renderToPrev(camera);
      renderer.clear();
    }

    // apply 32-bit post and tonemap from 32-bit color to 8-bit color
    //renderer.renderPostProcessHDR();
    // apply 8-bit post and draw
    renderer.renderPostProcessLDR();

    //renderer.pingpongbuffers();
    stats.end();
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();

    //timer.startTime = Date.now();
    count = 0;
  }, false);

  document.addEventListener('mousedown', function(event) {
    
    let x = event.clientX;
    let y = window.innerHeight - event.clientY;
    mouseCount = 10 * numIters;
    if(controls.mouseExplosion) {
      renderer.updateMouse(x,y);
      renderer.updateMouseCount(mouseCount);
      renderer.updateMouseRadius(controls.mouseRadius);
    }
    if(controls.useMouseClick) {
      renderer.updateMouseDiffuseDir(x,y,1,1);
    }
    mouseDown = true;
  });
  document.addEventListener('mousemove', function(event) {
    if(mouseDown) {
      let x = event.clientX;
      let y = window.innerHeight - event.clientY;
      mouseCount = 10 * numIters;
      if(controls.mouseExplosion) {
        renderer.updateMouse(x,y);
        renderer.updateMouseCount(mouseCount);
      }
      if(controls.useMouseClick) {
        renderer.updateMouseDiffuseDir(x,y,1,1);
      }
    }
  });
  document.addEventListener('mouseup', function(event) {
    if(!mouseDown) {
      return;
    }
    let x = event.clientX;
    let y = window.innerHeight - event.clientY;
    mouseCount = 0;
    if(controls.mouseExplosion) {
      renderer.updateMouse(x,y);
      renderer.updateMouseCount(mouseCount);
    }

    mouseDown = false;
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}


function setup() {
  timer.startTime = Date.now();
  loadOBJText();
  main();
}

setup();


