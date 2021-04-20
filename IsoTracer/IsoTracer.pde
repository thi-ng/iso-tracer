/**
 * .___           ___________
 * |   | _________\__    ___/___________    ____  ___________
 * |   |/  ___/  _ \|    |  \_  __ \__  \ _/ ___\/ __ \_  __ \
 * |   |\___ (  <_> )    |   |  | \// __ \\  \__\  ___/|  | \/
 * |___/____  >____/|____|   |__|  (____  /\___  >___  >__|
 *          \/                          \/     \/    \/
 *
 * (c) 2011 Karsten Schmidt
 */
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.color.*;
import toxi.math.*;
import toxi.util.*;
import java.util.*;

int numSamples = 1;
int superSamples = 0;

float eyeDistance = 300;
float occlusionDistance = 200;
float occlusionAmp = 0.71;

ReadonlyTColor bgCol = TColor.newGray(0.9);

boolean doUpdate = false;
boolean doSave = false;

AABB sceneBounds = new AABB(new Vec3D(0, 0, 0), new Vec3D(1000, 1000, 1000));
List<SceneItem> items;
Terrain terrain;

PImage renderTarget;
Raytracer trace;

float phase = 0;

void setup() {
  size(1280, 720);
  //size(640, 640);
  renderTarget = createImage(width, height, ARGB);
  fill(0);
  terrain = new Terrain(8, 8, 40);
  randomizeTerrain();
  initRaytracer();
}

void draw() {
  background(bgCol.toARGB());
  loadPixels();
  //trace.setEyeDistance(200 + mouseY - height / 2);
  if (doUpdate) {
    phase++;
  }
  items = new ArrayList<SceneItem>();
  
  // scene #1
  items.add(new SceneItem(new BoxIntersector(new AABB(new Vec3D(10, 0, 150 * sin(phase * 0.05f)), new Vec3D(20, 20, 100))), TColor.WHITE));
  items.add(new SceneItem(new BoxIntersector(new AABB(new Vec3D(85, 100 * sin(phase * 0.066f), 0), new Vec3D(20, 100, 20))), TColor.GREEN));
  items.add(new SceneItem(new SphereIntersectorReflector(new Sphere(new Vec3D(200 * sin(phase * 0.073f), -70, 50), 50)), TColor.WHITE));
  items.add(new SceneItem(new MeshIntersector(((TriangleMesh) new Plane(new Vec3D(0.1f, 0.1f, -40), new Vec3D(0, 0, 1)).toMesh(250)).rotateZ(QUARTER_PI)), TColor.WHITE));
  items.add(new SceneItem(new MeshIntersector(((TriangleMesh) new Plane(new Vec3D(0.1f, 0.1f, 0), new Vec3D(1, 0, 0)).toMesh(350))), TColor.YELLOW));
  
  // scene #2
  // items.add(new SceneItem(new MeshIntersector(((TriangleMesh) terrain.toMesh()).rotateX(HALF_PI).translate(0, 0, -100)), TColor.WHITE));
  // items.add(new SceneItem(new MeshIntersector(((TriangleMesh) new Plane(new Vec3D(0.1f, 0.1f, -100), new Vec3D(0, 0, 1)).toMesh(400)).rotateZ(QUARTER_PI)), TColor.WHITE));

  trace.setIntersectors(items);
  trace.clearRenderBuffer();
  long t0 = System.nanoTime();
  trace.render();
  double taken = (System.nanoTime() - t0) * 1e-6;

  renderTarget.updatePixels();
  image(renderTarget, 0, 0);
  text("taken: " + taken, 20, 20);
  text("eyeDist: " + eyeDistance, 20, 40);
  text("phase: " + phase, 20, 60);
  if (doSave) {
    String path = "IsoTracer-" + DateUtils.timeStamp() + ".png";
    renderTarget.save(path);
    println("wrote: " + path);
    doSave = false;
  }
}

Vec2D getIsoPos(Vec3D p) {
  float x = p.x + p.y;
  float y = -p.z - p.x * 0.5f + p.y * 0.5f;
  return new Vec2D(x, y);
}

void initRaytracer() {
  trace = new Raytracer();
  trace.setRenderBuffer(renderTarget.pixels, renderTarget.width, renderTarget.height);
  trace.setAspect((float) height / width);
  trace.setHasBackground(false);
  // trace.setClipRect(new Rect(width / 2 - 100, height / 2 - 100, 200, 200));
  trace.setSceneBounds(sceneBounds);
  trace.setCameraMatrix(new Matrix4x4().rotateZ(QUARTER_PI).rotateX(Math.atan(1/2.0)));
  trace.setEyeDistance(eyeDistance);
  trace.setOcclusionDistance(occlusionDistance);
  trace.setOcclusionAmp(occlusionAmp);
  trace.initScatterTable(4096);
  trace.setNumSamples(numSamples);
  trace.setSuperSamples(superSamples);
}

void keyPressed() {
  if (key >= '1' && key <= '9') {
    trace.setNumSamples((int) pow(2, (key - '0')));
    if (key > '1') {
      doSave = true;
    }
  }
  switch (key) {
  case ' ':
    doSave = true;
    break;
  case 'u':
    doUpdate = !doUpdate;
    break;
  case 'r':
    randomizeTerrain();
    break;
  }
}

void randomizeTerrain() {
  float[] el = terrain.getElevation();
  for (int i = 0; i < el.length; i++) {
    el[i] = MathUtils.random(200);
  }
  terrain.updateElevation();
}
