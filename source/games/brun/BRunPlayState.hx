package games.brun;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.util.FlxCollision;

class BRunPlayState extends BRunState {
  public var curPlayer:String = 'bf';
  var player:BaseChar;
  var spawnPoint:FlxPoint;

  // Collision
  var cameraBounds:FlxGroup;
  var levelBounds:FlxGroup;
  var hGroup:FlxTypedGroup<FlxSprite>;

  override public function create() {
    super.create();

    final map = new TiledMap("assets/brunner/levels/Level1.tmx");
    final hLayer:TiledObjectLayer = cast(map.getLayer("hitboxes"));
    final vLayer:TiledImageLayer = cast(map.getLayer("level_visual"));
    hGroup = new FlxTypedGroup<FlxSprite>();

    trace('Map: $map');
    trace('Hixboxes: $hLayer');

    spawnPoint = new FlxPoint(0, 0);

    for (hitbox in hLayer.objects) {
      if (hitbox.name == "spawn") {
        spawnPoint.set(hitbox.x, hitbox.y);
        continue;
      }
      final hitbox = new FlxSprite(hitbox.x, hitbox.y);
      hitbox.makeGraphic(Std.int(hitbox.width), Std.int(hitbox.height), FlxColor.WHITE);
      hitbox.immovable = true;
      hGroup.add(hitbox);
    }
    add(hGroup);

    switch (curPlayer) {
      default:
        player = new Boyfriend();
    }

    add(player);
    player.x = spawnPoint.x;
    player.y = spawnPoint.y;

    cameraBounds = FlxCollision.createCameraWall(FlxG.camera, true, 1);
  }

  override public function update(e:Float) {
    super.update(e);
    FlxG.collide(player, cameraBounds);
    FlxG.collide(player, hGroup);
  }
}
