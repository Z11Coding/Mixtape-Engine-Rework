package games.brun;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.util.FlxCollision;

class BRunPlayState extends BRunState {
  public var curPlayer:String = 'bf';
  var levelBounds:FlxGroup;
  var player:BaseChar;

  override function create() {
    super.create();

    final map = new TiledMap("assets/brunner/levels/Level1.tmx");
    final hLayer:TiledObjectLayer = cast(map.getLayer("hitboxes"));
    final hGroup = new FlxTypedGroup<FlxSprite>();

    switch (curPlayer) {
      default:
        player = new Boyfriend();
    }

    for (hitbox in hLayer.objects) {
      final hitbox = new FlxSprite(hitbox.x, hitbox.y);
      hitbox.makeGraphic(Std.int(hitbox.width), Std.int(hitbox.height), FlxColor.WHITE);
      hGroup.add(hitbox);
    }
    add(hGroup);

    add(player);

    levelBounds = FlxCollision.createCameraWall(FlxG.camera, true, 1);
  }
}
