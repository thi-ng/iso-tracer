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
class Raytracer {
  Matrix4x4 camMatrix;
  Vec3D rayDir;
  List<SceneItem> intersectors;
  ReadonlyTColor bgCol = TColor.WHITE;

  float eyeDist = 250;
  float occlusionDist = 200;
  float superSamples = 1;
  int numSamples = 2;

  int[] renderBuf;
  int width, height;
  int w2, h2;
  float aspect;
  boolean hasBackground;
  
  Vec3D[] scatterTable;
  final ShadingState state = new ShadingState();
  float occlusionAmp = 1;

  AABB sceneBounds = new AABB(new Vec3D(), Float.MAX_VALUE / 2);
  Rect clipRect;

  final Ray3D isecRay = new Ray3D();
  final Ray3D occlusionRay = new Ray3D();

  float computeOcclusion(ReadonlyVec3D pos, ReadonlyVec3D normal) {
    float totalSum = 0;
    float escSum = 0;
    occlusionRay.set(pos.add(normal.getNormalizedTo(0.001f)));
    for (int j = 0; j < numSamples; j++) {
      Vec3D c;
      while (true) {
        c = scatterTable[MathUtils.random(scatterTable.length)];
        if (c.dot(normal) > 0) {
          occlusionRay.setNormalizedDirection(c);
          break;
        }
      }
      float theta = normal.dot(c);
      totalSum += theta;
      float isecDist = Float.MAX_VALUE;
      for (SceneItem i : intersectors) {
        if (i.isOccluder && i.intersector.intersectsRay(occlusionRay)) {
          isecDist = MathUtils.min(isecDist, i.intersector.getIntersectionData().dist);
          if (isecDist < occlusionDist) break;
        }
      }
      if (isecDist > occlusionDist) escSum += theta;
    }
    return 1 - escSum / totalSum;
  }

  void initScatterTable(int num) {
    scatterTable = new Vec3D[num];
    Vec3D s = new Vec3D();
    while (num > 0) {
      s.set(MathUtils.normalizedRandom(), MathUtils.normalizedRandom(), MathUtils.normalizedRandom());
      if (s.magSquared() > 1) continue;
      scatterTable[--num] = s.getNormalized();
    }
  }

  void render() {
    for (int y = (int) clipRect.y, y2 = (int) clipRect.getBottom(); y < y2; y++) {
      for (int x = (int) clipRect.x, x2 = (int) clipRect.getRight(), idx = y * width + x; x < x2; x++, idx++) {
        shootRay(x, y, superSamples);
        if (state.radiance != -1) {
          TColor col = TColor.BLACK.getBlended(state.minIsec.diffuse, state.radiance);
          renderBuf[idx] = hasBackground
            ? state.alpha < 1 ? col.blend(bgCol, 1 - state.alpha).toARGB() : col.toARGB()
            : state.alpha < 1 ? col.setAlpha(state.alpha).toARGB() : col.toARGB();
        }
      }
    }
  }

  void shootRay(int x, int y, float ss) {
    float occlusion = 0;
    int hitCount = 0;
    int rayCount = 0;
    float y1 = ss < 1 ? y - 0.5f : y;
    float y2 = ss < 1 ? y + 0.5f : y;
    float x1 = ss < 1 ? x - 0.5f : x;
    float x2 = ss < 1 ? x + 0.5f : x;
    state.minD = Float.MAX_VALUE;
    state.minIsec = null;
    for (float yy = y1; yy <= y2; yy += ss) {
      for (float xx = x1; xx <= x2; xx += ss) {
        updateIntersectionRayFor(xx, yy);
        float minD = Float.MAX_VALUE;
        SceneItem minIsec = null;
        for (SceneItem i : intersectors) {
          if (i.isVisible && i.intersector.intersectsRay(isecRay)) {
            float d = i.intersector.getIntersectionData().dist;
            if (d < minD && sceneBounds.containsPoint(i.intersector.getIntersectionData().pos)) {
              minD = d;
              minIsec = i;
            }
          }
        }
        if (minIsec != null) {
          IsectData3D isec = minIsec.intersector.getIntersectionData();
          ReadonlyVec3D pos = isec.pos;
          ReadonlyVec3D n = isec.normal;
          if (n.dot(rayDir) > 0) n = n.getInverted();
          occlusion += computeOcclusion(pos, n);
          hitCount++;
          if (minD < state.minD) {
            state.minD = minD;
            state.minIsec = minIsec;
          }
        }
        rayCount++;
      }
    }
    if (hitCount > 0) {
      state.radiance = 1 - occlusion / hitCount * occlusionAmp;
      state.alpha = (float) hitCount / rayCount;
    } else {
      state.radiance = -1;
    }
  }

  protected void updateIntersectionRayFor(float x, float y) {
    isecRay.set((x - w2) / w2, -(y - h2) / h2 * aspect, 1).normalize();
    camMatrix.applyToSelf(isecRay.scaleSelf(eyeDist / isecRay.z));
  }
  
  //////////////// getters
  
  float getAspect() { return aspect; }

  ReadonlyTColor getBackgroundColor() { return bgCol; }

  Matrix4x4 getCameraMatrix() { return camMatrix; }

  Rect getClipRect() { return clipRect; }

  float getEyeDistance() { return eyeDist; }

  List<SceneItem> getIntersectors() { return intersectors; }

  int getNumSamples() { return numSamples; }

  float getOcclusionAmp() { return occlusionAmp; }

  float getOcclusionDistance() { return occlusionDist; }

  int[] getRenderBuffer() { return renderBuf; }

  AABB getSceneBounds() { return sceneBounds; }

  float getSuperSamples() { return 1f / superSamples; }

  boolean hasBackground() { return hasBackground; }
  
  //////////////// setters
  
  void clearRenderBuffer() { Arrays.fill(renderBuf, hasBackground ? bgCol.toARGB() : 0); }
  
  void setAspect(float aspect) { this.aspect = aspect; }

  void setBackgroundColor(ReadonlyTColor bgCol) { this.bgCol = bgCol; }

  void setCameraMatrix(Matrix4x4 camMatrix) {
    this.camMatrix = camMatrix;
    rayDir = camMatrix.applyTo(new Vec3D(0, 0, -1)).normalize();
    isecRay.setNormalizedDirection(rayDir);
  }

  void setRenderBuffer(int[] renderBuf, int width, int height) {
    this.renderBuf = renderBuf != null ? renderBuf : new int[width * height];
    this.width = width;
    this.height = height;
    this.w2 = width / 2;
    this.h2 = height / 2;
    setAspect((float) width / height);
    if (clipRect == null) setClipRect(new Rect(0, 0, width, height));
  }
  
  void setClipRect(Rect clipRect) { this.clipRect = clipRect; }

  void setEyeDistance(float eyeDist) { this.eyeDist = eyeDist; }

  void setHasBackground(boolean hasBackground) { this.hasBackground = hasBackground; }

  void setIntersectors(List<SceneItem> items) { this.intersectors = items; }

  void setNumSamples(int numSamples) { this.numSamples = numSamples; }

  void setOcclusionAmp(float occlusionAmp) { this.occlusionAmp = occlusionAmp; }

  void setOcclusionDistance(float d) { this.occlusionDist = d; }
  
  void setSceneBounds(AABB sceneBounds) { this.sceneBounds = sceneBounds; }

  void setSuperSamples(int superSamples) { this.superSamples = 1f / (1 + superSamples); }
}
