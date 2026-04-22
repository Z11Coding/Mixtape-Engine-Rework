package archipelago.substates;

class QuickSongSelect extends MusicBeatSubstate {
  public var selectedSongs:Array<String> = [];
  public var songList:Array<String> = [];

  private var grpSongs:FlxTypedGroup<DynamicColoredAlphabet>;
  private static var curSelected:Int = 0;
  var lerpSelected:Float = 0;

  var searchBar:PsychUIInputText;

  override function create() {
    APSettingsSubState.generateSongList();

    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bg.alpha = 0.6;
    add(bg);

    grpSongs = new FlxTypedGroup<DynamicColoredAlphabet>();
		add(grpSongs);

    songList = APInfo.allSongs;
    updateTexts();
    super.create();
    if (songList.length > 0) {
      for (song in 0...songList.length) {
        var songText:DynamicColoredAlphabet = new DynamicColoredAlphabet(90, 320, songList[song], true, 0xFFFFFF, true);
        songText.doShuffle = false;
        songText.targetY = song;
        grpSongs.add(songText);
      }
    } else {
      var songText:DynamicColoredAlphabet = new DynamicColoredAlphabet(90, 320, 'NO SONGS IN LIST!', true, true);
      songText.doShuffle = false;
      songText.targetY = 0;
      grpSongs.add(songText);
    }
    lerpSelected = curSelected;
    changeSelection();

    searchBar = new PsychUIInputText(0, 0, 800, '', 20);
    searchBar.screenCenter(X);
		//searchBar.x -= 200;
		add(searchBar);
		searchBar.bg.color = FlxColor.GRAY;
    searchBar.selection.color = FlxColor.RED;
		searchBar.textObj.alignment = FlxTextAlign.CENTER;
		searchBar.textObj.bold = true;
		searchBar.textObj.font = Paths.font("FridayNightFunkin.ttf");
		searchBar.updateHitbox();
  }

  var holdTime:Float = 0;
  var e:Float = 0;
  override function update(el:Float) {
    e++;
    var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

    if(FlxG.keys.justPressed.HOME)
    {
      curSelected = 0;
      changeSelection();
      holdTime = 0;
    }
    else if(FlxG.keys.justPressed.END)
    {
      curSelected = songList.length - 1;
      changeSelection();
      holdTime = 0;
    }
    if (controls.UI_UP_P)
    {
      changeSelection(-shiftMult);
      holdTime = 0;
    }
    if (controls.UI_DOWN_P)
    {
      changeSelection(shiftMult);
      holdTime = 0;
    }

    if(controls.UI_DOWN || controls.UI_UP)
    {
      var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
      holdTime += el;
      var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

      if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
        changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
    }

    if(FlxG.mouse.wheel != 0)
    {
      FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
      changeSelection(-shiftMult * FlxG.mouse.wheel, false);
    }

    if (controls.BACK)
    {
      persistentUpdate = false;
      FlxG.sound.play(Paths.sound('cancelMenu'));
      close();
    }

    if (controls.ACCEPT)
		{
      if (!APInfo.excludedSongs.contains(songList[curSelected]))
        APInfo.excludedSongs.push(songList[curSelected]);
      else
        APInfo.excludedSongs.remove(songList[curSelected]);

      grpSongs.forEach(function(item:DynamicColoredAlphabet)
      {
        if (APInfo.excludedSongs.contains(item.text))
          item.color = FlxColor.RED;
        else
          item.color = FlxColor.WHITE;
      });
    }
    updateTexts(el);
    super.update(el);
  }

  function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		curSelected += change;

		if (curSelected < 0) curSelected = songList.length - 1;
		if (songList.length > 0 && curSelected >= songList.length)
    if (change > 0) curSelected = 0;
    else curSelected = songList.length - 1;

		try {
			if (songList.length >= 0)
			{
				if (curSelected < 0)
					curSelected = songList.length - 1;
				if (curSelected >= songList.length)
					curSelected = 0;
			}
		}
		catch(e)
		{
			trace('NO SONGS FOUND! Running Freeplay anyway...');
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.4;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}

		try {
			if (songList[curSelected] == null)
				return;
		}
		catch(e)
		{
			trace("songs couldn't be found, even though there are songs??? adding SONG NOT FOUND just in case.");
		}

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

  var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			if(grpSongs.members[i] != null) grpSongs.members[i].visible = grpSongs.members[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songList.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songList.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (grpSongs.members[i] != null)
			{
				if (!(grpSongs.members[i] is Scrollable)) {
					continue;
				}

				var item:Scrollable = cast(grpSongs.members[i], Scrollable);
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				_lastVisibles.push(i);
			}
		}
	}
}
