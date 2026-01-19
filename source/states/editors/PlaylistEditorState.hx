package states.editors;
import states.PlaylistState.PlaylistMetadata;
import states.editors.content.PsychJsonPrinter;
import states.freeplay.backend.DifficultyStars;

class PlaylistEditorState extends MusicBeatState
{
  public static var autoOpenMetaEditor:Bool = false;

  public var playlists:Array<PlaylistMetadata> = [];
  public var selectedPlaylist:PlaylistMetadata = null;
  private var grpPlaylist:FlxTypedGroup<Alphabet>;
  public var curSelected:Int = 0;
  var lerpSelected:Float = 0;

  var bg:FlxSprite;
  var playlistTitle:Alphabet;
  public function new(currentPlaylist:PlaylistMetadata = null)
  {
    super();

    selectedPlaylist = currentPlaylist;
  }

  override public function create():Void
  {
    playlists = PlaylistState.loadPlaylists();

    if (playlists.length <= 0 || selectedPlaylist == null)
    {
      trace("No playlists found!");
      FlxG.switchState(new PlaylistSelector());
    }

    bg = new FlxSprite();
    playlistTitle = new Alphabet(20, 0, 'title', true);
    playlistTitle.scaleX = playlistTitle.scaleY = 0.8;
		playlistTitle.screenCenter(X);
    grpPlaylist = new FlxTypedGroup<Alphabet>();
    loadPlaylist(selectedPlaylist);
    add(bg);
    add(grpPlaylist);
    add(playlistTitle);
    super.create();

    var sizeMulti:Int = 2;

    var playlistSelect:PsychUIButton = new PsychUIButton(0, (FlxG.height - 50), 'Playlist Select', function()
		{
      FlxTransitionableState.skipNextTransIn = true;
      FlxG.switchState(new PlaylistSelector());
		}, 80*sizeMulti, 20*sizeMulti);
    playlistSelect.x = (FlxG.width/2) - playlistSelect.width - 250;

    var editMetadata:PsychUIButton = new PsychUIButton((playlistSelect.x + playlistSelect.width)+50, playlistSelect.y, 'Edit Metadata', function()
		{
      openSubState(new PlaylistMetaDataEditor(selectedPlaylist));
		}, 80*sizeMulti, 20*sizeMulti);

    var deletePlaylist:PsychUIButton = new PsychUIButton((editMetadata.x+editMetadata.width)+50, editMetadata.y, 'Delete Playlist', function()
		{
      openSubState(new Prompt('Are you sure you want to delete ${selectedPlaylist.playlistName}?\n(THIS CANNOT BE UNDONE!)', 0, function() {
        ClientPrefs.data.playLists.remove(selectedPlaylist);
        ClientPrefs.saveSettings();

        for (playlist in ClientPrefs.data.playLists) {
          if (playlist.playlistName == selectedPlaylist.playlistName) {
            ClientPrefs.data.playLists.remove(playlist);
            ClientPrefs.saveSettings();
            break;
          }
        }

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
                var fileName:String = file.substr(0, file.length - 5);
                if (fileName == selectedPlaylist.playlistName) {
                  FileSystem.deleteFile(path);
                  break;
                }
              }
            }
          }
        }
        #end

        FlxTransitionableState.skipNextTransIn = true;
        FlxG.switchState(new PlaylistSelector());
      }, null, false, 'Yes', 'Cancel'));
		}, 80*sizeMulti, 20*sizeMulti);
    deletePlaylist.normalStyle.bgColor = FlxColor.RED;
		deletePlaylist.normalStyle.textColor = FlxColor.WHITE;

    var reorderSongs:PsychUIButton = new PsychUIButton((deletePlaylist.x+deletePlaylist.width)+50, deletePlaylist.y, 'Re-Arrange Songs', function()
		{
      // Nothing for now
		}, 80*sizeMulti, 20*sizeMulti);
    add(playlistSelect);
    add(editMetadata);
    add(deletePlaylist);
    add(reorderSongs);

    updateTexts();
    lerpSelected = curSelected;
    changeSelection();

    if (autoOpenMetaEditor) {
      autoOpenMetaEditor = false;
      openSubState(new PlaylistMetaDataEditor(selectedPlaylist));
    }
  }

  function loadPlaylist(playlist:PlaylistMetadata) {
    if (playlist == null) {
      bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
      bg.antialiasing = ClientPrefs.data.antialiasing;
      bg.screenCenter();

      playlistTitle.text = 'No Playlist Selected';

      grpPlaylist.clear();
    } else {
      bg.loadGraphic(Paths.image(playlist.bg ?? ClientPrefs.getBGImage()));
      bg.antialiasing = ClientPrefs.data.antialiasing;
      bg.screenCenter();

      playlistTitle.text = playlist.playlistName;
      playlistTitle.screenCenter(X);

      grpPlaylist.clear();
      for (i in 0...playlist.songList.length) {
        var playlistText:Alphabet = new Alphabet(90, 320, playlist.songList[i].songName, true);
        playlistText.targetY = i;
        playlistText.scaleX = Math.min(1, 980 / playlistText.width);
				playlistText.snapToPosition();
        playlistText.visible = playlistText.active = playlistText.isMenuItem = false;
        grpPlaylist.add(playlistText);
      }
    }
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    updateTexts(elapsed);

    if (controls.ACCEPT)
    {
      // do nothing for now
    }
    else if (controls.BACK)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
      FlxTransitionableState.skipNextTransIn = true;
      MusicBeatState.switchState(new PlaylistState());
    }
    else if (controls.UI_UP_P)
    {
      changeSelection(-1);
    }
    else if (controls.UI_DOWN_P)
    {
      changeSelection(1);
    }
  }

  function changeSelection(change:Int = 0) {
    curSelected += change;
    if (curSelected < 0)
      curSelected = grpPlaylist.length - 1;
    else if (curSelected >= grpPlaylist.length)
      curSelected = 0;

    var bullShit:Int = 0;
    for (item in grpPlaylist.members)
		{
			bullShit++;
			item.alpha = 0.4;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
  }

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			if(grpPlaylist.members[i] != null) grpPlaylist.members[i].visible = grpPlaylist.members[i].active = false;
			//try{if(iconArray[i] != null) iconArray[i].visible = iconArray[i].active = false;}
			//catch(e) {trace("Failed to update the icons!");}
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(grpPlaylist?.members.length ?? 1, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(grpPlaylist?.members.length ?? 1, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (grpPlaylist.members[i] != null)
			{
				var item = grpPlaylist.members[i];
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				_lastVisibles.push(i);
			}
		}
	}
}

class PlaylistSelector extends MusicBeatState {
  private var grpPlaylist:FlxTypedGroup<Alphabet>;
  var curSelected:Int = 0;
  var lerpSelected:Float = 0;
  var playlists:Array<PlaylistMetadata> = PlaylistState.loadPlaylists();


  var newPlaylistText:Scrollable;
  override public function create():Void
  {
    super.create();
    var bg:FlxSprite = new FlxSprite();
    bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.alpha = 0.4;
    add(bg);
    bg.screenCenter();

    grpPlaylist = new FlxTypedGroup<Alphabet>();
		add(grpPlaylist);

    newPlaylistText = new Alphabet(90, 320, "NEW PLAYLIST +", true);
		newPlaylistText.scaleX = Math.min(1, 980 / newPlaylistText.width);
		newPlaylistText.targetY = -1;
		newPlaylistText.snapToPosition();
		add(cast newPlaylistText);

    var chooseText:Alphabet = new Alphabet((FlxG.width/2), (-FlxG.height + 150), "Select a Playlist to Edit", true);
    chooseText.setAlignmentFromString("center");
    newPlaylistText.snapToPosition();
    //chooseText.screenCenter(X);
    add(chooseText);

    for (i in 0...playlists.length) {
      var playlistText:Alphabet = new Alphabet(90, 320, playlists[i].playlistName, true);
      playlistText.targetY = i;
      grpPlaylist.add(playlistText);
    }

    updateTexts();
    changeSelection(0);

  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    updateTexts(elapsed);

    if (controls.ACCEPT)
    {
      FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
      if (curSelected == -1) {
        openSubState(new PlaylistMetaDataEditor(null));
      } else {
        var selectedPlaylist:PlaylistMetadata = playlists[curSelected];
        FlxTransitionableState.skipNextTransIn = true;
        MusicBeatState.switchState(new PlaylistEditorState(selectedPlaylist));
      }
    }
    else if (controls.BACK)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
      FlxTransitionableState.skipNextTransIn = true;
      MusicBeatState.switchState(new PlaylistState());
    }
    else if (controls.UI_UP_P)
    {
      changeSelection(-1);
    }
    else if (controls.UI_DOWN_P)
    {
      changeSelection(1);
    }
  }

  function changeSelection(change:Int = 0) {
    curSelected += change;
    if (curSelected < -1)
      curSelected = grpPlaylist.length - 1;
    else if (curSelected >= grpPlaylist.length)
      curSelected = -1;

    var bullShit:Int = 0;
    for (item in grpPlaylist.members)
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

  var selected:Bool = false;
  private function updateScrollable(obj:Scrollable, elapsed:Float = 0.0) {
		obj.x = ((obj.targetY - lerpSelected) * obj.distancePerItem.x) + obj.startPosition.x;
		obj.y = ((obj.targetY - lerpSelected) * 1.3 * obj.distancePerItem.y) + obj.startPosition.y;

		if (selected)
			obj.alpha -= elapsed * 4;
		else
			obj.alpha = FlxMath.bound(obj.alpha + elapsed * 5, 0, 0.6);
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			if(grpPlaylist.members[i] != null) grpPlaylist.members[i].visible = grpPlaylist.members[i].active = false;
			//try{if(iconArray[i] != null) iconArray[i].visible = iconArray[i].active = false;}
			//catch(e) {trace("Failed to update the icons!");}
		}
		_lastVisibles = [];

		updateScrollable(newPlaylistText, elapsed);
		if (curSelected == -1)
			newPlaylistText.alpha = 1;

		var min:Int = Math.round(Math.max(0, Math.min(playlists.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(playlists.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (grpPlaylist.members[i] != null)
			{
				if (!(grpPlaylist.members[i] is Scrollable)) {
					continue;
				}

				var item:Scrollable = cast(grpPlaylist.members[i], Scrollable);
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				_lastVisibles.push(i);
			}
		}
	}
}

class PlaylistMetaDataEditor extends MusicBeatSubstate {
  public static var playlist:PlaylistMetadata;
  static var oldPlaylist:PlaylistMetadata;

  public function new(playlist:PlaylistMetadata = null)
  {
    super();
    PlaylistMetaDataEditor.playlist = playlist;
    PlaylistMetaDataEditor.oldPlaylist = playlist;
  }

  var diffStars:DifficultyStars;
  var mainBox:PsychUIBox;

  var playlistNameInputText:PsychUIInputText;
  var playlistBGInputText:PsychUIInputText;
  var playlistIconInputText:PsychUIInputText;
  var playlistAlbumInputText:PsychUIInputText;
  var playlistDifficultySlider:PsychUISlider;
  override public function create():Void
  {
    super.create();
    Cursor.show();
    var bg:FlxSprite = new FlxSprite();
    bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bg.alpha = 0.5;
    add(bg);

    mainBox = new PsychUIBox(0, 0, 600, 320, ['Metadata']);
		mainBox.selectedName = 'Metadata';
		mainBox.scrollFactor.set();
    mainBox.screenCenter(X);
		add(mainBox);

    makeUIThings();
    reloadUI();
  }

  function makeUIThings() {
    var tab_group = mainBox.getTab('Metadata').menu;
    var objX = 10;
		var objY = 25;

    playlistNameInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		playlistNameInputText.onChange = function(old:String, cur:String)
      if (PlaylistMetaDataEditor.playlist != null) PlaylistMetaDataEditor.playlist.playlistName = cur;

    objY += 40;
    playlistBGInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		playlistBGInputText.onChange = function(old:String, cur:String)
      if (PlaylistMetaDataEditor.playlist != null) PlaylistMetaDataEditor.playlist.bg = cur;

    objY += 40;
    playlistIconInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		playlistIconInputText.onChange = function(old:String, cur:String)
      if (PlaylistMetaDataEditor.playlist != null) PlaylistMetaDataEditor.playlist.icon = cur;

    objX += 140;
    objY = 25;
    playlistAlbumInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		playlistAlbumInputText.onChange = function(old:String, cur:String)
      if (PlaylistMetaDataEditor.playlist != null) PlaylistMetaDataEditor.playlist.album = cur;

    objY += 40;
    playlistDifficultySlider = new PsychUISlider(objX, objY, function(v:Float) {
      if (PlaylistMetaDataEditor.playlist != null) PlaylistMetaDataEditor.playlist.difficulty = Std.int(v);
      setStars(Std.int(v));
    }, 0, 0, 20, 200);
    playlistDifficultySlider.decimals = 0;
		playlistDifficultySlider.label = 'Difficulty:';

    diffStars = new DifficultyStars(playlistDifficultySlider.x - 25, playlistDifficultySlider.y + 35);
		diffStars.visible = true;
		diffStars.scrollFactor.set();
		tab_group.add(diffStars);

    objY += 125;
    objX = 10;
    var songSelect:PsychUIButton = new PsychUIButton(objX, objY, 'Song Select', function()
		{
      PlaylistEditorState.autoOpenMetaEditor = true;
      FlxG.switchState(new PlaylistSongSelectorState());
		}, 80);

    objX += 120;
    var savePlaylist:PsychUIButton = new PsychUIButton(objX, objY, 'Save Playlist', function()
		{
      var promptSave:Prompt;
      var saveInternal = function()
      {
        trace('Playlist: ${PlaylistMetaDataEditor.playlist}');
        if (PlaylistMetaDataEditor.oldPlaylist != null) { // cant delete what isnt there lol
          if (ClientPrefs.data.playLists.contains(PlaylistMetaDataEditor.oldPlaylist))
            ClientPrefs.data.playLists.remove(PlaylistMetaDataEditor.oldPlaylist);
        }

        ClientPrefs.data.playLists.push(PlaylistMetaDataEditor.playlist);
        ClientPrefs.saveSettings();

        if (PlaylistMetaDataEditor.oldPlaylist != null) { // cant delete what isnt there lol
          var playlists:Array<PlaylistMetadata> = ClientPrefs.data.playLists;

          var directories:Array<String> = [
            Paths.mods(Mods.currentModDirectory + '/playlists/'),
            Paths.mods('playlists/'),
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
                  var fileName:String = file.substr(0, file.length - 5);
                  if (fileName == PlaylistMetaDataEditor.oldPlaylist.playlistName) {
                    FileSystem.deleteFile(file);
                    break;
                  }
                }
              }
            }
          }
        }

        openSubState(new Prompt('Save Successful!', 1, function() {
          states.editors.PlaylistEditorState.autoOpenMetaEditor = false;
          MusicBeatState.switchState(new PlaylistEditorState(PlaylistMetaDataEditor.playlist));
        }, null, false, 'OK', 'its actually very not ok'));
      };
      var saveExternal = function()
      {
        var playlistData:String = PsychJsonPrinter.print(PlaylistMetaDataEditor.playlist);
        if (ImprovedFileHandling.saveOperation('Save Playlist', {ext: "json", desc: "JSON File"}, Text, playlistData)) {
          trace("Saved playlist externally!");
          openSubState(new Prompt('Save Successful!', 1, function() {
            states.editors.PlaylistEditorState.autoOpenMetaEditor = false;
            MusicBeatState.switchState(new PlaylistEditorState(PlaylistMetaDataEditor.playlist));
          }, null, false, 'OK', 'its actually very not ok'));
        } else {
          trace("Failed to save playlist externally.");
          openSubState(new Prompt('Save Failed!', 1, function() {
            states.editors.PlaylistEditorState.autoOpenMetaEditor = false;
            MusicBeatState.switchState(new PlaylistEditorState(PlaylistMetaDataEditor.playlist));
          }, null, false, 'OK', 'its actually very not ok'));
        }
      };
      openSubState(new Prompt('How would you like to save your playlist?', 0, saveInternal, saveExternal, false, 'Save Internally', 'Save Externally'));
		}, 80);

    tab_group.add(new FlxText(playlistNameInputText.x, playlistNameInputText.y - 15, 180, 'Playlist Name:'));
    tab_group.add(new FlxText(playlistBGInputText.x, playlistBGInputText.y - 15, 180, 'Playlist BG:'));
    tab_group.add(new FlxText(playlistIconInputText.x, playlistIconInputText.y - 15, 180, 'Playlist Icon:'));
    tab_group.add(new FlxText(playlistAlbumInputText.x, playlistAlbumInputText.y - 15, 180, 'Playlist Album:'));
    tab_group.add(new FlxText(playlistDifficultySlider.x, playlistDifficultySlider.y - 15, 180, 'Playlist Difficulty:'));
    tab_group.add(playlistNameInputText);
    tab_group.add(playlistBGInputText);
    tab_group.add(playlistIconInputText);
    tab_group.add(playlistAlbumInputText);
    tab_group.add(playlistDifficultySlider);
    tab_group.add(savePlaylist);
    tab_group.add(songSelect);
  }

  function reloadUI() {
    if (PlaylistMetaDataEditor.playlist == null)
      PlaylistMetaDataEditor.playlist = new PlaylistMetadata('unnammed playlist', 'menuDesat', 'bf', 'nocover', [0, 0, 0], []);

    playlistNameInputText.text = playlist.playlistName;
    playlistBGInputText.text = playlist.bg;
    playlistIconInputText.text = playlist.icon;
    playlistAlbumInputText.text = playlist.album;
    playlistDifficultySlider.value = playlist.difficulty;
    setStars(playlist.difficulty);
  }

  function setStars(value:Int) {
    if (diffStars != null) {
      diffStars.setNumber(value);
      diffStars.visible = true;
    }
  }

  var lastFocus:PsychUIInputText;
  override function update(elapsed:Float) {
    super.update(elapsed);
    var playlistFocus:Bool = PsychUIInputText.focusOn == null && lastFocus == null;
    ClientPrefs.toggleVolumeKeys(playlistFocus);

    if (playlistFocus && controls.BACK) {
      PlaylistEditorState.autoOpenMetaEditor = false;
      PlaylistMetaDataEditor.playlist = null;
      close();
    }
    lastFocus = PsychUIInputText.focusOn;
  }
}
