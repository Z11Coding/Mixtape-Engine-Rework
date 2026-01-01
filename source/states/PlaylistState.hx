package states;
import backend.Highscore;
import backend.WeekData;
import flixel.addons.ui.FlxUIInputText; // TODO: get rid of this in place of the psych varient
import objects.Alphabet.DynamicAlphabet;
import objects.Character;
import objects.HealthIcon;
import states.PlaylistState.PlaylistMetadata;
import states.freeplay.backend.DifficultyStars;
import yutautil.AprilFools;
class PlaylistState extends MusicBeatState {
  public var loadedPlaylists:Array<PlaylistMetadata> = [];

  private static var curSelected:Int = 0;
  var lerpSelected:Float = 0;

  var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

  private var grpPlaylists:FlxTypedGroup<Alphabet>;
	private var iconList:FlxTypedGroup<HealthIcon>;
  private var iconArray:Array<HealthIcon> = [];
  var selected:Bool = false;
	var bg:FlxSprite;

  var randomText:Scrollable;
	var randomIcon:HealthIcon;

  public var searchBar:FlxUIInputText;

  var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;

  var albumPhoto:FlxSprite;
	var difficultyStars:DifficultyStars;
  var rank:RankingManager;
  public static var doChange:Bool = false;

  override function create()
	{
    #if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end
		Cursor.cursorMode = Default;
    Highscore.reloadModifiers();
    Paths.clearStoredWithoutStickers();

    persistentUpdate = true;
		PlayState.isStoryMode = false;

    #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Selecting Their Mixtape...", null);
		#end

    Mods.loadTopMod();

    bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

    if (ClientPrefs.data.allowVis) {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				visual = new AudioDisplay(FlxG.sound.music, 0, FlxG.height, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				visual.scrollFactor.set(0, 0);
				add(visual);
				visual.alpha = ClientPrefs.data.visOpacity;

				vocalvisual = new AudioDisplay(FlxG.sound.music, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				vocalvisual.scrollFactor.set(0, 0);
				vocalvisual.flipY = true;
				add(vocalvisual);
				vocalvisual.alpha = ClientPrefs.data.visOpacity;

				oppvisual = new AudioDisplay(FlxG.sound.music, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				oppvisual.scrollFactor.set(0, 0);
				oppvisual.flipY = true;
				add(oppvisual);
				oppvisual.alpha = ClientPrefs.data.visOpacity;
			}
		}

    grpPlaylists = new FlxTypedGroup<Alphabet>();
		add(grpPlaylists);

    iconList = new FlxTypedGroup<HealthIcon>();
		add(iconList);

    randomText = new Alphabet(90, 320, "RANDOM", true);
		randomText.scaleX = Math.min(1, 980 / randomText.width);
		randomText.targetY = -1;
		randomText.snapToPosition();
		add(cast randomText);

		randomIcon = new HealthIcon('bf');
		randomIcon.sprTracker = cast randomText;
		randomIcon.scrollFactor.set(1, 1);
		add(randomIcon);

		albumPhoto = new FlxSprite(930, 0).loadGraphic(Paths.image('albums/NoCover'));
		albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
		albumPhoto.screenCenter(Y);
		albumPhoto.y += 20;
		add(albumPhoto);
		albumPhoto.alpha = 0.6;

		difficultyStars = new DifficultyStars(albumPhoto.x, albumPhoto.y - 130);
		difficultyStars.visible = true;
    difficultyStars.scrollFactor.set();
    add(difficultyStars);

		reloadPlayLists();

		if (loadedPlaylists.length < 1) {
      FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO PLAYLISTS FOUND!\n\nPress ACCEPT to go to the Playlist Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.PlaylistEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
    }

    //Search bar my belovid
		searchBar = new FlxUIInputText(FlxG.height, 100, 800, '', 20);
		searchBar.screenCenter(X);
		//searchBar.x -= 200;
		add(searchBar);
		searchBar.backgroundColor = FlxColor.GRAY;
		searchBar.lines = 1;
		searchBar.autoSize = false;
		searchBar.alignment = FlxTextAlign.CENTER;
		searchBar.bold = true;
		searchBar.font = Paths.font("FridayNightFunkin.ttf");
		searchBar.alpha = 0.8;
		searchBar.text = 'CLICK TO SEARCH FREEPLAY!';
		searchBar.updateHitbox();

    FlxG.mouse.visible = true;

    scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

    rank = new RankingManager('small');
		rank.updateHitbox();
		rank.screenCenter(XY);
		rank.y = 640 - rank.height;
		rank.x = FlxG.width/2 - 590;
    add(rank);

    lerpSelected = curSelected;

    bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

    updateTexts();

    super.create();
    changeSelection();

    rank.doTween('in');
  }

  public function setDifficultyStars(?difficulty:Int):Void
	{
		if (difficulty == null) return;
		difficultyStars.setNumber(archipelago.APItem.unknownSongs ? 100 : difficulty);
		showStars();
	}

	/**
	 * Make the album stars visible.
	 * I thought this was pointless.
	 * Turns out, this DOES have a reason to exist
	 */
	public function showStars():Void
	{
		difficultyStars.visible = true; // true;
	}

  override function closeSubState() {
		if (doChange)
		{
			changeSelection(0);
			doChange = false;
			Highscore.reloadModifiers();
		}
		persistentUpdate = true;
		super.closeSubState();
	}

	function changeSelection(change:Int = 0) {
    curSelected += change;
    if (curSelected < -1)
      curSelected = grpPlaylists.length - 1;
    else if (curSelected >= grpPlaylists.length)
      curSelected = -1;

		var bullShit:Int = 0;
    for (item in grpPlaylists.members)
		{
			bullShit++;
			item.alpha = 0.4;
			if (item.targetY == curSelected)
				item.alpha = 1;
			if (item is Scrollable) {
				if (cast(item, Scrollable).targetY == curSelected)
					item.alpha = 1;
			}
		}
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
  }

  override function update(elapse:Float) {
    super.update(elapse);

		updateTexts(elapse);

		if (controls.ACCEPT)
    {
      // TODO: playlist stuff
    }
    else if (controls.BACK)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
      FlxTransitionableState.skipNextTransIn = true;
      MusicBeatState.switchState(new MainMenuState());
    }
    else if (controls.UI_UP)
    {
      changeSelection(-1);
    }
    else if (controls.UI_DOWN)
    {
      changeSelection(1);
    }
  }

  function reloadPlayLists() {
    grpPlaylists.clear();

    loadedPlaylists = loadPlaylists();

		if (loadedPlaylists.length == 0) {
			trace('no need to do anything if there\'s nothing to do');
			// no need to do anything if there's nothing to do
			return;
		}

    for (i in 0...loadedPlaylists.length - 1) {
      var listText:Alphabet = null;
      listText = new DynamicAlphabet(90, 320, loadedPlaylists[i].playlistName, true, true);
      listText.doShuffle = AprilFools.allowAF ? FlxG.random.bool(10) : false;
      listText.targetY = i;
			grpPlaylists.add(listText);
    }

    //if I need to do anything else, this function will be here
  }

  function switchVisualizer(?hasVocals:Bool = false, ?vocalSND:FlxSound = null, ?oppSND:FlxSound = null) {
		if (ClientPrefs.data.allowVis) {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				if (visual != null) remove(visual);
				visual = new AudioDisplay(FlxG.sound.music, 0, FlxG.height, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				visual.scrollFactor.set(0, 0);
				add(visual);
				visual.alpha = 0.7;

				if (hasVocals) {
					if (vocalSND != null) {
						if (vocalvisual != null) remove(vocalvisual);
						var color:Array<Int> = Character.grabCharInfo(PlayState.SONG.player1).get("Health Colors");
						vocalvisual = new AudioDisplay(vocalSND, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, color != null ? FlxColor.fromRGB(color[0], color[1], color[2]) : FlxColor.WHITE);
						vocalvisual.scrollFactor.set(0, 0);
						vocalvisual.flipY = true;
						add(vocalvisual);
						vocalvisual.alpha = 0.7;
					}

					if (oppSND != null) {
						if (oppvisual != null) remove(oppvisual);
						var color:Array<Int> = Character.grabCharInfo(PlayState.SONG.player2).get("Health Colors");
						oppvisual = new AudioDisplay(oppSND, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.fromRGB(color[0], color[1], color[2]));
						oppvisual.scrollFactor.set(0, 0);
						oppvisual.flipY = true;
						add(oppvisual);
						oppvisual.alpha = 0.7;
					}
				} else {
					if (vocalvisual != null) remove(vocalvisual);
					if (oppvisual != null) remove(oppvisual);
				}
			}
		}
	}

	public static function loadPlaylists():Array<PlaylistMetadata>
	{
		var playlists:Array<PlaylistMetadata> = ClientPrefs.data.playLists ?? [];

		// mod-specific playlist support maybe??? idk could be cool
		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('playlists/'),
			Paths.mods(Mods.currentModDirectory + '/playlists/'),
			Paths.getSharedPath('playlists/')
		];
		for (mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/playlists/'));
		for (directory in directories)
		{
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var rawJson:String = File.getContent(file);
						if(rawJson != null && rawJson.length > 0)
						{
							var playlistData:PlaylistMetadata = cast tjson.TJSON.parse(rawJson);
							if (playlistData != null)
							{
								var isDupe:Bool = false;
								//TODO: find a better way to check for dupes
								for (playlist in playlists)
								{
									if (playlist.playlistName == playlistData.playlistName)
									{
										trace('Playlist "' + playlistData.playlistName + '" already exists! Skipping duplicate from ' + path);
										isDupe = true;
										continue;
									}
								}
								if (!isDupe)
									playlists.push(playlistData);
							}
						}
					}
				}
			}
		}
		#end
		return playlists;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			if(grpPlaylists.members[i] != null) grpPlaylists.members[i].visible = grpPlaylists.members[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(loadedPlaylists.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(loadedPlaylists.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (grpPlaylists.members[i] != null)
			{
				var item = grpPlaylists.members[i];
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				_lastVisibles.push(i);
			}
		}
	}
}

class PlaylistSongMetadata extends managers.FreeplayManager.GlobalSongMetadata
{
	public var difficulty:String = "";
	public function new(song:String, week:Int, songCharacter:String, color:Array<Array<Dynamic>>, difficulty:String = "", ?charter:String = "???", ?artist:String = "???")
	{
		super(song, week, songCharacter, color, );
		this.difficulty = difficulty;
		this.charter = charter;
		this.artist = artist;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}

}

class PlaylistMetadata
{
	public var playlistName:String = "";
	public var bg:String = "";
	public var icon:String = "";
	public var album:String = "";
	public var difficulty:Int = -1;
	public var color:Array<Dynamic> = [];
	public var songList:Array<PlaylistSongMetadata> = [];
	public function new(?playlistName:String = 'unnamed playlist', ?bg:String = 'menuDesat', ?icon:String = 'bf', ?album:String = 'nocover', ?color:Array<Dynamic>, ?songList:Array<PlaylistSongMetadata>)
	{
		this.playlistName = playlistName;
		this.bg = bg;
		this.icon = icon;
		this.album = album;
		this.color = color;
		this.songList = songList;
	}
}
