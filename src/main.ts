import {vec2} from 'gl-matrix';
import {vec3} from 'gl-matrix';
import {vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Cube from './geometry/Cube';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  movingSpeed: 2.0,
  morphingSpeed: 0.5,
  patternSize: 2.0,
  tesselations: 8,
  'Load Scene': loadScene, // A function pointer, essentially
  Color : [242,174,62],
};

// let cube : Cube;
let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 7;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0.99));
  square.create();
  // cube = new Cube(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  // cube.create();
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
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 1, 8).step(1);
  gui.add(controls, 'morphingSpeed', 0.05, 4.0);
  gui.add(controls, 'movingSpeed', 0.05, 4.0);
  gui.add(controls, 'patternSize', 0.5, 16.0);
  gui.add(controls, 'Load Scene');
  gui.addColor(controls, 'Color');

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

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const shaderFireBall = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);
  const shaderBackground = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  let startTime = new Date().getTime();

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      loadScene();
    }

    shaderBackground.setFov(camera.fovy);
    shaderBackground.setTime((new Date().getTime() - startTime) / 1000.0);
    shaderBackground.setWindowSize(vec2.fromValues(window.innerWidth, window.innerHeight));
    let camTarget = vec3.create();
    vec3.add(camTarget, camera.position, camera.direction);
    shaderBackground.setTarget(camera.getEye());
    shaderBackground.setEye(camera.getTarget());

    renderer.render(camera, shaderBackground, [
      square,
    ]);

    shaderFireBall.setGeometryColor(vec4.fromValues(controls.Color[0] / 255.0, controls.Color[1] / 255.0, controls.Color[2] / 255.0, 1.0));
    shaderFireBall.setTime((new Date().getTime() - startTime) / 1000.0);
    shaderFireBall.setMovingSpeed(controls.movingSpeed);
    shaderFireBall.setPatternSize(controls.patternSize);
    shaderFireBall.setMorphingSpeed(controls.morphingSpeed);
    renderer.render(camera, shaderFireBall, [
      icosphere,
    ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
