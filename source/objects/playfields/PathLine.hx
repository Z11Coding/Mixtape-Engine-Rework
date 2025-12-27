package objects.playfields;

class PathLine extends Note { // have it extend note so most of the work is done for me lol
  public function new(?strumTime:Float, ?noteData:Int) {
    super(strumTime, noteData, null, false, false, null, false);
    makeGraphic(10, 10, 0xFFFFFFFF);
    this.objType = NOTE;
    this.column = noteData != null ? noteData : 0;
    this.rgbShader.enabled = false;
    this.animation.destroyAnimations(); // just in case
  }
}
