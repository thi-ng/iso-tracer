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
class SceneItem {
  Intersector3D intersector;
  ReadonlyTColor diffuse;
  
  boolean isVisible = true;
  boolean isOccluder = true;

  SceneItem(Intersector3D intersector, ReadonlyTColor col) {
    this(intersector, col, true, true);
  }
  
  SceneItem(Intersector3D intersector, ReadonlyTColor col, boolean isVisible, boolean isOccluder) {
    this.intersector = intersector;
    this.diffuse = col;
    this.isVisible = isVisible;
    this.isOccluder = isOccluder;
  }
}
