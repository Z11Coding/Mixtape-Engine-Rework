package games.brun;

class BRunState extends FlxState {

  override function update(elapsed:Float) {
    super.update(elapsed);
    FmodManager.Update();
  }

  override public function onFocus():Void
  {
    super.onFocus();
    FmodManager.SetWindowFocused(true);
    FmodManager.SetEventParameterOnSong("HighPass", 0);
  }

  override public function onFocusLost():Void
  {
    super.onFocusLost();
    FmodManager.SetEventParameterOnSong("HighPass", 1);
  }
}
