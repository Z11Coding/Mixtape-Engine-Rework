package debug;

#if projection_probe

import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import haxe.CallStack;
import haxe.Json;
import haxe.Timer;
import managers.MegaManager;
import managers.PlayfieldManager;
import managers.ScriptManager;
import objects.notes.Note;
import objects.notes.PreloadNotes;
import objects.notes.Strumline;
import objects.notes.SustainNote;
import objects.funkin.graphics.ProjectionView3D;
import objects.funkin.graphics.TexturedPlane3D;
import objects.funkin.graphics.ZSpriteProjected;
import objects.funkin.graphics.FieldProjection3D;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.events.UncaughtErrorEvent;
import openfl.geom.Vector3D;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.utils.UInt8Array;
import sys.FileSystem;
import sys.io.File;

/** Standalone, opt-in GPU probe. Does not run Main or the interactive startup/menu. */
class ProjectionProbeMain
{
  public static var output:String;
  public static var log:Array<String> = [];
  public static var results:Array<Dynamic> = [];

  public static function main():Void
  {
    output = Sys.getEnv("MIXTAPE_PROBE_OUT");
    if (output == null) output = Sys.getCwd() + "/projection-probe";
    FileSystem.createDirectory(output);
    Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(e) {
      e.preventDefault();
      fail(e.error);
    });
    #if cpp
    untyped __global__.__hxcpp_set_critical_error_handler(function(error:Dynamic) { fail(error); });
    #end
    write("Starting isolated renderer probe (no input, audio, save loading or desktop capture).");
    FlxG.autoPause = false;
    var state:Class<FlxState> = Sys.getEnv("MIXTAPE_FIELD_DEMO") == "1" ? FieldProjectionDemo : ProjectionProbeState;
    Lib.current.addChild(new FlxGame(1280, 720, state, 60, 60, true, false));
  }

  public static function write(message:String):Void
  {
    log.push(message);
    File.saveContent(output + "/probe.log", log.join("\n"));
  }

  public static function fail(error:Dynamic):Void
  {
    write("FAIL: " + Std.string(error) + "\n" + CallStack.toString(CallStack.exceptionStack()));
    File.saveContent(output + "/result.json", Json.stringify({passed: false, error: Std.string(error), cases: results}, null, "  "));
    Sys.exit(1);
  }

  /** Capture the real OpenGL scene to its own framebuffer, without desktop/OSD text. */
  @:access(openfl.display.BitmapData)
  @:access(openfl.display3D.Context3D)
  public static function capture(name:String):Void
  {
    if (Sys.getEnv("MIXTAPE_CAPTURE_WINDOW") == "1")
    {
      var bitmap = BitmapData.fromImage(Lib.application.window.readPixels());
      File.saveBytes(output + "/" + name + ".png", bitmap.encode(bitmap.rect, new PNGEncoderOptions()));
      bitmap.dispose();
      return;
    }
    var width = FlxG.width;
    var height = FlxG.height;
    var target = new BitmapData(width, height, true, FlxG.camera.bgColor);
    target.readable = false; // Select OpenFL's actual GPU renderer, including shaders/UVT.
    target.draw(FlxG.game, null, null, null, null, true);
    var context = Lib.current.stage.context3D;
    var previousTarget = context.__state.renderToTexture;
    var previousDepth = context.__state.renderToTextureDepthStencil;
    var previousAA = context.__state.renderToTextureAntiAlias;
    var previousSurface = context.__state.renderToTextureSurfaceSelector;
    context.setRenderToTexture(target.getTexture(context), true);
    context.__flushGLFramebuffer();
    context.__flushGLViewport();
    var gl = context.gl;
    var raw = new UInt8Array(width * height * 4);
    gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, raw);
    if (previousTarget == null) context.setRenderToBackBuffer();
    else context.setRenderToTexture(previousTarget, previousDepth, previousAA, previousSurface);
    context.__flushGLFramebuffer();
    context.__flushGLViewport();
    // OpenFL's render-to-texture projection already uses top-down image order.
    var bitmap = BitmapData.fromImage(new Image(new ImageBuffer(raw, width, height, 32, RGBA32)));
    File.saveBytes(output + "/" + name + ".png", bitmap.encode(bitmap.rect, new PNGEncoderOptions()));
    bitmap.dispose();
    target.dispose();
  }
}

@:access(objects.notes.SustainNote)
@:access(objects.notes.Strumline)
@:access(objects.notes.NoteSplash)
class ProjectionProbeState extends FlxState
{
  var line:Strumline;
  var label:FlxText;
  var phase:Int = -1;
  var tick:Int = 0;
  var totalUpdate:Float = 0;
  var maxUpdate:Float = 0;
  var totalDraw:Float = 0;
  var maxDraw:Float = 0;
  var samples:Int = 0;
  var animatedFrames:Int = 0;
  var lastAnimFrame:Int = -1;
  var snapshots:Int = 0;
  var previousHoldRoots:Array<Array<Float>> = [];
  var holdMeshMoved:Bool = false;
  var cases:Array<String> = ["2d", "3d", "paths", "3d-paths", "3d-flip-crop", "3d-back-face"];

  override public function create():Void
  {
    super.create();
    FlxG.autoPause = false;
    FlxG.sound.volume = 0;
    FlxG.mouse.enabled = false;
    FlxG.mouse.visible = false;
    FlxG.keys.enabled = false;
    FlxG.camera.bgColor = 0xFF151923;
    backend.ClientPrefs.data.downScroll = false;
    backend.ClientPrefs.data.middleScroll = false;
    MegaManager.playfield = new PlayfieldManager();
    MegaManager.playfield.skipArrowStartTween = true;
    MegaManager.scriptManager = new ScriptManager();
    MegaManager.conductor = new backend.RConductor();
    ProjectionProbeMain.write("Splash diagnostics: preference=" + backend.ClientPrefs.data.splashSkin + ", default="
      + backend.ClientPrefs.defaultData.splashSkin + ", postfix=" + objects.notes.NoteSplash.getSplashSkinPostfix()
      + ", root image=" + Paths.fileExists("images/noteSplashes.png", IMAGE)
      + ", root xml=" + Paths.fileExists("images/noteSplashes.xml", TEXT)
      + ", root atlas=" + (Paths.getSparrowAtlas("noteSplashes") != null));
    label = new FlxText(24, 20, 1220, "", 20);
    add(label);
    validatePlaneTransform();
    FlxG.signals.postDraw.add(afterDraw);
    nextCase();
  }

  function validatePlaneTransform():Void
  {
    var view = new ProjectionView3D();
    view.configure(1280, 720, 90, 0, 100);
    var neutral = new Vector3D(123, 234, 0);
    view.project(neutral, 80, -30, 0.99);
    if (Math.abs(neutral.x - 123) > 0.000001 || Math.abs(neutral.y - 234) > 0.000001)
      throw "Neutral projection moved the existing note position";
    var sprite = new ZSpriteProjected();
    sprite.makeGraphic(128, 96, 0xFFFFFFFF, true);
    var plane = new TexturedPlane3D();
    var actual = new Vector3D();
    var expected = new Vector3D();
    var comparisons = 0;
    sprite.sharedProjectionPlanes = [];
    for (variant in 0...8)
    {
      sprite.angle = variant * 17;
      sprite.angleX = variant * 9;
      sprite.angleY = variant * -13;
      sprite.scale.set(0.7 + variant * 0.07, 1.1);
      sprite.scaleX2 = 0.9;
      sprite.scaleY2 = 1.2;
      sprite.cropLeft = variant * 0.025;
      sprite.cropBottom = 0.1;
      sprite.flipX = variant % 2 == 1;
      sprite.flipY = variant % 3 == 1;
      sprite.skew.set(7, -4);
      sprite.skewX_playfield = 3;
      sprite.skewY_playfield = -2;
      sprite.skewZ = 5;
      sprite.pivotOffsetX = 11;
      sprite.pivotOffsetY = -6;
      sprite.x = variant * 19;
      sprite.y = variant * 37;
      plane.prepare(sprite, 128, 96, 3, -2, true);
      for (i in 0...12)
      {
        var u = i / 11.0;
        var v = ((i * 7) % 12) / 11.0;
        var dx = i % 3 - 1;
        var dy = i % 5 - 2;
        var dz = i % 7 - 3;
        expected.setTo(3 + 128 * u + dx, -2 + 96 * v + dy, dz);
        sprite.transformPlaneVertex(expected, u, v, 128, 96);
        plane.transform(actual, u, v, dx, dy, dz);
        if (Math.abs(actual.x - expected.x) > 0.00001 || Math.abs(actual.y - expected.y) > 0.00001
          || Math.abs(actual.z - expected.z) > 0.00001) throw "Prepared plane changed a spatial transform parameter";
        comparisons++;
      }
      var shared = TexturedPlane3D.obtain(sprite, plane, 128, 96, 3, -2, true);
      sprite.x += 210;
      sprite.y -= 175;
      var reused = TexturedPlane3D.obtain(sprite, plane, 128, 96, 3, -2, true);
      if (shared != reused) throw "Moving along a lane rebuilt an identical plane";
      expected.setTo(3 + 128 * 0.4 + 2, -2 + 96 * 0.7 - 3, 4);
      sprite.transformPlaneVertex(expected, 0.4, 0.7, 128, 96);
      reused.transform(actual, 0.4, 0.7, 2, -3, 4, sprite);
      if (Math.abs(actual.x - expected.x) > 0.00001 || Math.abs(actual.y - expected.y) > 0.00001
        || Math.abs(actual.z - expected.z) > 0.00001) throw "Lane cache changed the existing note position/skew";
    }
    sprite.destroy();
    ProjectionProbeMain.write("PASS: neutral projection identity and " + comparisons + " prepared-plane equivalence checks.");
  }

  function nextCase():Void
  {
    if (line != null)
    {
      remove(line);
      // Exercise the same owner cleanup used when leaving a song, twice.
      MegaManager.playfield.resetFields();
      MegaManager.playfield.resetFields();
      line = null;
    }
    phase++;
    if (phase >= cases.length)
    {
      // Repeated state-style ownership cleanup, including frame clearing.
      for (cycle in 0...8)
      {
        makeLine();
        MegaManager.playfield.resetFields();
        line = null;
      }
      ProjectionProbeMain.write("PASS: renderer cases and repeated PlayfieldManager.resetFields completed.");
      ProjectionProbeMain.write("Shared planes: preparations=" + TexturedPlane3D.preparations + ", reuses=" + TexturedPlane3D.reuses);
      File.saveContent(ProjectionProbeMain.output + "/result.json", Json.stringify({passed: true, cases: ProjectionProbeMain.results}, null, "  "));
      Sys.exit(0);
      return;
    }
    makeLine();
    add(line);
    tick = samples = animatedFrames = 0;
    lastAnimFrame = -1;
    totalUpdate = maxUpdate = totalDraw = maxDraw = 0;
    snapshots = 0;
    previousHoldRoots = [];
    holdMeshMoved = false;
    ProjectionProbeMain.write("CASE " + cases[phase]);
  }

  function makeLine():Void
  {
    MegaManager.playfield.skipArrowStartTween = true;
    line = new Strumline({strumlinePos: FlxPoint.get(180, 90), player: 0}, false, 0.7, true);
    line.active = false; // Advance objects explicitly; no PlayState, audio or physical input.
    line.x = 180;
    line.txtActiveMods.visible = false;
    line.drawArrowPaths = phase == 2 || phase == 3;
    MegaManager.playfield.allStrumLines.push(line);
    for (i in 0...4)
    {
      var receptor = line.getByColumn(i);
      receptor.formerPosition.set(line.x + line.getXPos(i), 90);
      receptor.strumExtraModData.introTweenPercentage = 1;
      receptor.playConfirm();
    }
    line.mods.addMod("3d", phase == 1 || phase >= 3 ? 1 : 0);
    line.mods.addMod("anglex", 16);
    line.mods.addMod("angley", 22);
    // `z` is in pixels; `movez` is in receptor widths and must not receive pixels.
    line.mods.addMod("z", phase == 0 ? 0 : -180);
    line.mods.addMod("arrowpath", line.drawArrowPaths ? 0.45 : 0);
    line.mods.sortMods();
    for (i in 0...24)
    {
      var n = new Note(0, i % 4, line);
      var data:PreloadNotes = {strumTime: 200 + i * 80.0, noteData: i % 4, row: -1};
      n.setupNoteData(data);
      n.active = false;
      line.notes.add(n);
    }
    for (i in 0...4)
    {
      var hold = new SustainNote(0, i, 550, line);
      var data:PreloadNotes = {strumTime: 350 + i * 160.0, noteData: i, sustainLength: 550, parentSL: 550, isSustainNote: true, isSustainEnd: true, row: -1};
      hold.setupNoteData(data);
      hold.usingHazModHolds = true;
      hold.active = false;
      line.sustainNotes.add(hold);
      // Preserve the skin's head/body proportions; perspective must not bake
      // an extra width scale into the hold before projecting it.
      var expectedWidth = hold.getHoldBodyFrame().frame.width * ExtraKeys.scales[ExtraKeys.mania];
      if (Math.abs(hold.graphicWidth - expectedWidth) > 0.00001)
        throw "Sustain mesh did not preserve the native skin width";
      var head = line.notes.members[i];
      var expectedCenter = Std.int(head.frame.sourceSize.x * ExtraKeys.scales[ExtraKeys.mania]) / 2;
      if (Math.abs(hold.headCenterX - expectedCenter) > 0.00001)
        throw "Sustain center did not match the actual note head";
    }
    var splash = line.constructNoteSplash(0);
    if (splash == null || !splash.visible || splash.animation.curAnim == null)
      throw "Gameplay note splash did not start an animation: " + Json.stringify({
        nullSplash: splash == null,
        visible: splash?.visible,
        texture: splash?.texture,
        noteData: splash?.noteData,
        animations: splash?.animation?.getNameList(),
        noteDataMap: splash == null ? null : [for (key => value in splash.noteDataMap) key + "=" + value]
      });
    line.mods.updateSpecialMods();
    line.mods.updateStrums();
  }

  override public function update(elapsed:Float):Void
  {
    // Fixed simulation delta makes the workload comparable despite background throttling.
    var start = Timer.stamp();
    tick++;
    var t = tick / 60.0;
    line.mods.setModVal("angley", phase == 5 ? 180 : Math.sin(t * 2) * 38);
    line.mods.setModVal("anglex", Math.cos(t) * 22);
    line.mods.setModVal("z", phase == 0 ? 0 : -160 + Math.sin(t) * 100);
    line.mods.updateSpecialMods();
    line.mods.updateStrums();
    for (i in 0...4)
    {
      var receptor = line.getByColumn(i);
      if (tick % 24 == 1) receptor.playConfirm();
      receptor.animation.update(1 / 60.0);
      if (phase == 4)
      {
        receptor.flipX = tick % 90 > 44;
        receptor.cropBottom = (Math.sin(t) + 1) * 0.15;
        receptor.invalidateMesh();
      }
    }
    var frame = line.getByColumn(0).animation.frameIndex;
    if (frame != lastAnimFrame) animatedFrames++;
    lastAnimFrame = frame;
    var index = 0;
    for (n in line.notes.members)
    {
      n.strumTime = 120 + ((index * 110 + tick * 8) % 1550);
      line.mods.setNotePos(n);
      n.animation.update(1 / 60.0);
      index++;
    }
    for (hold in line.sustainNotes.members)
    {
      hold.strumTime = 200 + ((hold.noteData * 160 + tick * 6) % 750);
    }
    // Use the same production update path as gameplay; calling the mesh builder
    // directly here would hide a broken Strumline sustain update.
    line.updateNotes();
    for (i in 0...line.sustainNotes.members.length)
    {
      var hold = line.sustainNotes.members[i];
      for (value in hold.vertices) checkFinite(value, "hold vertices");
      if (hold.vertices.length >= 2)
      {
        if (i < previousHoldRoots.length && (Math.abs(hold.vertices[0] - previousHoldRoots[i][0]) > 0.01
          || Math.abs(hold.vertices[1] - previousHoldRoots[i][1]) > 0.01)) holdMeshMoved = true;
        if (i >= previousHoldRoots.length) previousHoldRoots.push([hold.vertices[0], hold.vertices[1]]);
        else previousHoldRoots[i] = [hold.vertices[0], hold.vertices[1]];
      }
    }
    if (line.drawArrowPaths)
    {
      // Real Strumline.update builds and updates the arrowpath pieces.
      line.update(0);
    }
    var took = (Timer.stamp() - start) * 1000;
    if (tick > 30)
    {
      samples++;
      totalUpdate += took;
      if (took > maxUpdate) maxUpdate = took;
    }
    label.text = 'Projection probe: ${cases[phase]} | frame $tick\n4 receptors, 24 notes, 4 sustains; automatic animation / depth / rotation.\nNo OS mouse or keyboard input.';
  }

  override public function draw():Void
  {
    var states = [for (n in line.notes.members) [n.x, n.y, n.z, n.strumTime, n.animation.frameIndex]];
    var start = Timer.stamp();
    super.draw();
    var took = (Timer.stamp() - start) * 1000;
    if (tick > 30)
    {
      totalDraw += took;
      if (took > maxDraw) maxDraw = took;
    }
    for (r in line.strumLineNotes.members)
    {
      var expectProjection = phase == 1 || phase >= 3;
      if (r.projectionEnabled != expectProjection) throw "3D modifier did not match the test case";
      if (r.projectionEnabled)
      {
        if (r.vertices.length == 0 || r.indices.length == 0) throw "Empty receptor mesh";
        for (v in r.vertices) checkFinite(v, "receptor vertices");
        for (uv in r.uvtData) checkFinite(uv, "receptor UVs");
        for (i in 0...Std.int(r.uvtData.length / 3))
        {
          var u = r.uvtData[i * 3];
          var v = r.uvtData[i * 3 + 1];
          if (u < r.frame.uv.x - 0.00001 || u > r.frame.uv.width + 0.00001
            || v < r.frame.uv.y - 0.00001 || v > r.frame.uv.height + 0.00001)
            throw "Projected UV escaped its animation frame";
        }
      }
    }
    for (n in line.notes.members)
    {
      if (n.projectionEnabled)
        for (v in n.vertices) checkFinite(v, "note vertices");
    }
    for (i in 0...line.notes.members.length)
    {
      var n = line.notes.members[i];
      var before = states[i];
      if (n.x != before[0] || n.y != before[1] || n.z != before[2] || n.strumTime != before[3]
        || n.animation.frameIndex != before[4]) throw "Rendering changed note movement, time or animation state";
    }
  }

  function afterDraw():Void
  {
    if (tick == 70 || tick == 100)
    {
      var hold = line.sustainNotes.members[0];
      ProjectionProbeMain.write(Json.stringify({caseName: cases[phase], frame: tick, holdVisible: hold.visible,
        holdVertices: hold.vertices.length, holdUVs: hold.uvtData.length, holdWidth: hold.graphicWidth}));
      var r = line.getByColumn(0);
      var n = line.notes.members[1];
      ProjectionProbeMain.write(Json.stringify({receptor: r.frame.name, frameUV: Std.string(r.frame.uv),
        meshUV: [for (i in 0...12) r.uvtData[i]], uvScale: Std.string(r.uvScale), uvOffset: Std.string(r.uvOffset),
        note: n.frame.name, noteUV: Std.string(n.frame.uv), noteMeshUV: [for (i in 0...12) n.uvtData[i]],
        holdBody: hold.getHoldBodyFrame().name, holdBodyUV: Std.string(hold.getHoldBodyFrame().uv),
        holdCap: hold.getAnimationFrame(hold.animation.curAnim.name).name, holdMeshUV: [for (i in 0...8) hold.uvtData[i]]}));
      ProjectionProbeMain.capture('${cases[phase]}-$tick');
      snapshots++;
    }
    if (tick >= 150)
    {
      if (animatedFrames < 2) throw "Receptor animation did not advance";
      if (!holdMeshMoved) throw "Sustain mesh did not follow changing note positions";
      ProjectionProbeMain.results.push({name: cases[phase], samples: samples, updateMeanMs: totalUpdate / samples,
        updateMaxMs: maxUpdate, drawMeanMs: totalDraw / samples, drawMaxMs: maxDraw, animationFrameChanges: animatedFrames,
        holdMeshMoved: holdMeshMoved, screenshots: snapshots});
      ProjectionProbeMain.write(Json.stringify(ProjectionProbeMain.results[ProjectionProbeMain.results.length - 1]));
      nextCase();
    }
  }

  function checkFinite(value:Float, context:String):Void
  {
    if (!Math.isFinite(value)) throw "Non-finite " + context;
  }

  override public function destroy():Void
  {
    FlxG.signals.postDraw.remove(afterDraw);
    super.destroy();
  }
}

/** Whole-field demonstration. Every element uses ONE model matrix and pivot. */
@:access(objects.notes.SustainNote)
class FieldProjectionDemo extends FlxState
{
  var original:Strumline;
  var folded:Strumline;
  var label:FlxText;
  var phase:Int = -1;
  var tick:Int = 0;
  var cases = ["field-tilted", "mirror-open", "mirror-folding", "mirror-closed"];
  var seamX:Float;
  var seamY:Float;

  override public function create():Void
  {
    super.create();
    FlxG.autoPause = false;
    FlxG.sound.volume = 0;
    FlxG.mouse.enabled = false;
    FlxG.mouse.visible = false;
    FlxG.keys.enabled = false;
    FlxG.camera.bgColor = 0xFF151923;
    backend.ClientPrefs.data.downScroll = false;
    backend.ClientPrefs.data.middleScroll = false;
    MegaManager.playfield = new PlayfieldManager();
    MegaManager.scriptManager = new ScriptManager();
    MegaManager.conductor = new backend.RConductor();
    MegaManager.playfield.skipArrowStartTween = true;
    original = makeField();
    folded = makeField();
    add(original);
    add(folded);
    var red = original.getByColumn(3);
    seamX = red.x + red.width * 0.5;
    seamY = red.y + red.height * 0.5;
    original.projection3D.relativeCoordinates = false;
    folded.projection3D.relativeCoordinates = false;
    original.projection3D.setPivot(seamX, seamY);
    folded.projection3D.setPivot(seamX, seamY);
    folded.projection3D.mirrorX = true;
    validateFold();
    validateCoordinateSpaces();
    label = new FlxText(430, 24, 820, "", 22);
    add(label);
    FlxG.signals.postDraw.add(afterDraw);
    nextPose();
  }

  function makeField():Strumline
  {
    var line = new Strumline({strumlinePos: FlxPoint.get(100, 225), player: 0}, false, 0.65, true);
    line.active = false;
    line.x = 100;
    line.txtActiveMods.visible = false;
    line.drawArrowPaths = true;
    MegaManager.playfield.allStrumLines.push(line);
    for (i in 0...4)
    {
      var r = line.getByColumn(i);
      r.formerPosition.set(line.x + line.getXPos(i), 225);
      r.strumExtraModData.introTweenPercentage = 1;
      r.playStatic();
    }
    line.mods.addMod("3d", 1);
    line.mods.addMod("arrowpath", 0.10);
    line.mods.sortMods();
    line.mods.updateSpecialMods();
    line.mods.updateStrums();
    for (i in 0...4)
    {
      var time = 420.0 + i * 100;
      var n = new Note(0, i, line);
      n.setupNoteData({strumTime: time, noteData: i, row: -1});
      n.active = false;
      line.notes.add(n);
      var hold = new SustainNote(0, i, 390, line);
      hold.setupNoteData({strumTime: time, noteData: i, sustainLength: 390, parentSL: 390,
        isSustainNote: true, isSustainEnd: true, row: -1});
      hold.usingHazModHolds = true;
      hold.active = false;
      line.sustainNotes.add(hold);
    }
    return line;
  }

  function validateFold():Void
  {
    var matrix = new FieldProjection3D();
    matrix.relativeCoordinates = false;
    matrix.setPivot(seamX, seamY);
    matrix.mirrorX = true;
    matrix.setRotation(0, 180, 0);
    matrix.prepare();
    // At a 180-degree fold, a right-hand mirrored copy must land exactly
    // on the ORIGINAL field, including its red receptor and every path point.
    for (x in [180.0, 292.0, 404.0, seamX])
      for (y in [260.0, 400.0, 610.0])
      {
        var p = new Vector3D(x, y, 0);
        matrix.transform(p);
        if (Math.abs(p.x - x) > 0.000001 || Math.abs(p.y - y) > 0.000001 || Math.abs(p.z) > 0.000001)
          throw "Mirrored field did not fold back onto the same positions";
      }
    ProjectionProbeMain.write("PASS: mirrored field folds onto itself at 180 degrees using one pivot.");
  }

  function authoredField(x:Float, y:Float, down:Bool):FieldProjection3D
  {
    var field = new FieldProjection3D();
    field.setPivot(12, -18);
    field.setPosition(30, -50, -20);
    field.setRotation(25, 10, 15);
    field.prepareAutomaticPivot(x, y, down);
    return field;
  }

  function validateCoordinateSpaces():Void
  {
    var up = authoredField(400, 140, false);
    var down = authoredField(400, 580, true);
    var middle = authoredField(640, 140, false);
    var a = new Vector3D(480, 260, 20);
    var b = new Vector3D(480, 460, 20);
    var c = new Vector3D(720, 260, 20);
    up.transform(a); down.transform(b); middle.transform(c);
    if (Math.abs(a.x - b.x) > 0.000001 || Math.abs((a.y - 140) + (b.y - 580)) > 0.000001
      || Math.abs(a.z - b.z) > 0.000001) throw "Relative downscroll correction changed the authored pose";
    if (Math.abs(c.x - a.x - 240) > 0.000001 || Math.abs(c.y - a.y) > 0.000001
      || Math.abs(c.z - a.z) > 0.000001) throw "Relative coordinates did not follow the middle-scroll anchor";
    var absolute = new FieldProjection3D();
    absolute.relativeCoordinates = false;
    absolute.setPosition(640, 360);
    absolute.prepareAutomaticPivot(300, 140, false);
    a.setTo(300, 140, 0); absolute.transform(a);
    absolute.prepareAutomaticPivot(800, 580, true);
    b.setTo(800, 580, 0); absolute.transform(b);
    if (Math.abs(a.x - 640) > 0.000001 || Math.abs(a.y - 360) > 0.000001
      || Math.abs(a.x - b.x) > 0.000001 || Math.abs(a.y - b.y) > 0.000001)
      throw "Absolute screen coordinates changed with the scroll/layout mode";
    var uncorrected = new FieldProjection3D();
    uncorrected.correctScrollDirection = false;
    uncorrected.setPosition(0, -100);
    uncorrected.prepareAutomaticPivot(640, 580, true);
    a.setTo(640, 580, 0); uncorrected.transform(a);
    if (Math.abs(a.y - 480) > 0.000001) throw "Disabling scroll correction still inverted vertical movement";
    ProjectionProbeMain.write("PASS: relative up/downscroll, middle-scroll anchoring, absolute screen positions and disabled correction.");
  }

  function nextPose():Void
  {
    phase++;
    tick = 0;
    if (phase >= cases.length)
    {
      remove(original);
      remove(folded);
      MegaManager.playfield.resetFields();
      ProjectionProbeMain.write("PASS: whole-field poses, mirrored fold and cleanup.");
      File.saveContent(ProjectionProbeMain.output + "/result.json", Json.stringify({passed: true, cases: cases, foldAlignment: true, coordinateSpaces: true}));
      Sys.exit(0);
      return;
    }
    original.projection3D.enabled = phase == 0;
    // The shared field API also works without the old per-sprite 3d modifier.
    original.mods.setModVal("3d", phase == 0 ? 0 : 1);
    original.alpha = phase == 0 ? 1 : 0.28;
    folded.visible = phase > 0;
    // FlxSpriteGroup.visible propagates to children; keep the engine's debug
    // placeholder hidden after making the mirrored field visible again.
    original.txtActiveMods.visible = folded.txtActiveMods.visible = false;
    folded.projection3D.enabled = true;
    if (phase == 0)
    {
      original.projection3D.setRotation(38, 25, -8);
      original.projection3D.depth = -120;
    }
    folded.projection3D.setRotation(0, phase == 2 ? 60 : phase == 3 ? 180 : 0, 0);
    label.text = phase == 0 ? "Whole field: X 38 / Y 25 / Z -8\nShared pivot: receptors, notes, holds and paths."
      : phase == 1 ? "Original + mirrored copy on the right\nPivot: center of the rightmost receptor."
      : phase == 2 ? "Mirrored copy folded 60 degrees\nThe entire field rotates around one shared pivot."
      : "Full fold: 180 degrees\nThe mirrored copy overlaps the original field.";
    ProjectionProbeMain.write("POSE " + cases[phase] + " pivot=" + seamX + "," + seamY);
  }

  override public function update(elapsed:Float):Void
  {
    tick++;
    for (line in [original, folded])
    {
      line.getFieldProjection3D();
      line.mods.updateSpecialMods();
      line.mods.updateStrums();
      for (r in line.strumLineNotes.members)
      {
        r.strumExtraModData.arrowpathLength = 1100;
        r.strumExtraModData.arrowpathBackwardsLength = 0;
      }
      for (n in line.notes.members) line.mods.setNotePos(n);
      for (h in line.sustainNotes.members) h.updateClipping_mods(0);
      line.update(0);
    }
  }

  function afterDraw():Void
  {
    if (tick == 100)
    {
      ProjectionProbeMain.capture(cases[phase]);
    }
    if (tick >= 120) nextPose();
  }

  override public function destroy():Void
  {
    FlxG.signals.postDraw.remove(afterDraw);
    super.destroy();
  }
}

#end
