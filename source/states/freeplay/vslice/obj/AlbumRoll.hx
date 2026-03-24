package states.freeplay.vslice.obj;

import backend.pslice.SortUtil;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import objects.FunkinSprite;
import states.freeplay.vslice.DifficultyStars;
import states.freeplay.vslice.obj.Album;
import states.freeplay.vslice.obj.AlbumRegistry;

/**
 * The graphic for the album roll in the FreeplayState.
 * Simply set `albumID` to fetch the required data and update the textures.
 */
class AlbumRoll extends FlxSpriteGroup
{
  /**
   * The ID of the album to display.
   * Modify this value to automatically update the album art and title.
   */
  public var albumId(default, set):Null<String>;

  function set_albumId(value:Null<String>):Null<String>
  {
    if (this.albumId != value)
    {
      this.albumId = value;
      updateAlbum();
    }

    return value;
  }

  var newAlbumArt:FunkinSprite;
  var albumTitle:FunkinSprite;

  var difficultyStars:DifficultyStars;
  var _exitMovers:Null<VSliceFreeplayState.ExitMoverData>;
  var _exitMoversCharSel:Null<VSliceFreeplayState.ExitMoverData>;

  var albumData:Album;

  final ALBUM_ART_SYMBOL:String = "album art placeholder";

  public function new()
  {
    super();

    newAlbumArt = new FunkinSprite((FlxG.width - 240) - MobileScaleMode.gameNotchSize.x, 160, "freeplay/albumRoll/freeplayAlbum");
    newAlbumArt.visible = false;
    newAlbumArt.anim.onFinish.add(onAlbumFinish);
    add(newAlbumArt);

    difficultyStars = new DifficultyStars((FlxG.width - 240) - MobileScaleMode.gameNotchSize.x, newAlbumArt.y-25);
    difficultyStars.visible = false;
    add(difficultyStars);

    buildAlbumTitle("freeplay/albumRoll/volume1-text");
    albumTitle.visible = false;

    newAlbumArt.anim.onFinish.add(onAlbumFinish);
  }

  function onAlbumFinish(animName:String):Void
  {
    // Play the idle animation for the current album.
    if (animName != "idle")
    {
      newAlbumArt.anim.play('idle', true);
    }
  }

  /**
   * Load the album data by ID and update the textures.
   */
  function updateAlbum():Void
  {
    if (albumId == null)
    {
      trace("ALBUM IS NULL: " + albumId);
      this.visible = true;
      albumId = 'NoCover';
      return;
    }
    else
    {
      this.visible = true;
    }


    albumData = AlbumRegistry.instance.fetchEntry(albumId);

    var albumPath = albumData?.getAlbumArtAssetKey() ?? null;

    if (albumData == null || !Paths.exists('images/$albumPath.png')) //? changed this section
    {
      if(albumId != ''){
        FlxG.log.warn('Could not find album data for album ID: ${albumId}');
        trace('Could not find album data for album ID: ${albumId}');
      }

      if (albumData != null)
        trace('Path "images/${albumData.getAlbumArtAssetKey()}.png" doesn\'t exist!');
      else
        trace('Album data is null for album ID: ${albumId}\nResorting to NoCover.');
      albumPath = "freeplay/albumRoll/NoCover";
      difficultyStars.stars.visible = false;
      return;
    };

    // Update the album art.
    var albumGraphic = Paths.image(albumPath, null, false);
    newAlbumArt.replaceSymbolGraphic(ALBUM_ART_SYMBOL, albumGraphic);

    buildAlbumTitle(albumData.getAlbumTitleAssetKey());

    applyExitMovers();

    refresh();
  }

  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  /**
   * Apply exit movers for the album roll.
   * @param exitMovers The exit movers to apply.
   */
  public function applyExitMovers(?exitMovers:VSliceFreeplayState.ExitMoverData, ?exitMoversCharSel:VSliceFreeplayState.ExitMoverData):Void
  {
    if (exitMovers == null)
    {
      exitMovers = _exitMovers;
    }
    else
    {
      _exitMovers = exitMovers;
    }

    if (exitMovers == null) return;

    if (exitMoversCharSel == null)
    {
      exitMoversCharSel = _exitMoversCharSel;
    }
    else
    {
      _exitMoversCharSel = exitMoversCharSel;
    }

    if (exitMoversCharSel == null) return;

    exitMovers.set([newAlbumArt, difficultyStars],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });

    exitMoversCharSel.set([newAlbumArt, difficultyStars],
      {
        y: -175,
        speed: 0.8,
        wait: 0.1
      });
  }

  var titleTimer:Null<FlxTimer> = null;

  /**
   * Play the intro animation on the album art.
   */
  public function playIntro():Void
  {
    albumTitle.visible = false;
    newAlbumArt.visible = true;
    newAlbumArt.anim.play('intro', true);

    difficultyStars.visible = false;
    new FlxTimer().start(0.75, function(_) {
      showTitle();
      showStars();
      albumTitle.animation.play('switch');
    });
  }

  public function skipIntro():Void
  {
    // Weird workaround
    newAlbumArt.anim.play('switch', true);
    albumTitle.animation.play('switch');
  }

  public function showTitle():Void
  {
    albumTitle.visible = true;
  }

  public function buildAlbumTitle(assetKey:String):Void
  {
    if (albumTitle != null)
    {
      remove(albumTitle);
      albumTitle = null;
    }

    albumTitle = FunkinSprite.createSparrow((FlxG.width - 355) - MobileScaleMode.gameNotchSize.x, newAlbumArt.y+25, assetKey);
    albumTitle.visible = albumTitle.frames != null && newAlbumArt.visible;
    albumTitle.animation.addByPrefix('idle', 'idle0', 24, true);
    albumTitle.animation.addByPrefix('switch', 'switch0', 24, false);
    add(albumTitle);

    albumTitle.animation.finishCallback = (function(name) {
      if (name == 'switch') albumTitle.animation.play('idle');
    });
    albumTitle.animation.play('idle');

    albumTitle.zIndex = 1000;

    if (_exitMovers != null) _exitMovers.set([albumTitle],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });

    if (_exitMoversCharSel != null) _exitMoversCharSel.set([albumTitle],
      {
        y: -190,
        speed: 0.8,
        wait: 0.1
      });
  }

  public function setDifficultyStars(?difficulty:Int):Void
  {
    if (difficulty == null) return;
    difficultyStars.difficulty = difficulty;
  }

  /**
   * Make the album stars visible.
   */
  public function showStars():Void
  {
    difficultyStars.visible = true; // true;
    difficultyStars.flameCheck();
  }
}
