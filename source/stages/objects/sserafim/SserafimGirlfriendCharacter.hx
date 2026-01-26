package stages.objects.sserafim;

class SserafimGirlfriendCharacter extends Character
{
  public function new(x:Float, y:Float)
  {
    super(x, y, 'sserafim-gf', true, OTHER);
    this.isPlayerAlt = true;
  }

  public var isBeautiful:Bool = false;

  override public function playAnim(name:String, restart:Bool = false, reversed:Bool = false, frame:Int = 0)
  {
    if (isBeautiful)
    {
      super.playAnim(name + '-alt', restart, reversed, frame);
    }
    else
    {
      super.playAnim(name, restart, reversed, frame);
    }
  }
}
